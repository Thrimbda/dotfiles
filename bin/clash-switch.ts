#!/usr/bin/env -S node --experimental-strip-types
// A small Clash Verge/Mihomo proxy group switcher for axiom.
//
// SYNOPSIS:
//   hey .clash-switch.ts list
//   hey .clash-switch.ts switch NODE
//   hey .clash-switch.ts NODE
//   hey .clash-switch.ts
//
// OPTIONS:
//   -c, --controller URL  Clash/Mihomo controller URL [env: CLASH_CONTROLLER_URL]
//   -g, --group NAME      Proxy group to read/switch [env: CLASH_PROXY_GROUP]
//   -s, --secret SECRET   Controller API secret [env: CLASH_API_SECRET]
//       --json            Print list output as JSON
//   -h, --help            Show this help

const DEFAULT_CONTROLLER = "http://127.0.0.1:9090";
const DEFAULT_GROUP = "Nexitally";

type Command = "interactive" | "list" | "switch";

type Options = {
  command: Command;
  controller: string;
  group: string;
  json: boolean;
  secret?: string;
  node?: string;
};

type ProxyGroup = {
  name?: unknown;
  type?: unknown;
  now?: unknown;
  all?: unknown;
};

type GroupState = {
  all: string[];
  now?: string;
};

const HELP = `Usage:
  clash-switch.ts list [GROUP] [options]
  clash-switch.ts switch NODE [options]
  clash-switch.ts NODE [options]
  clash-switch.ts [options]

Commands:
  list              List every node in the target proxy group.
  switch NODE       Switch the target proxy group to NODE.
  NODE              Shorthand for switch NODE.
  no command        Open an interactive selector.

Options:
  -c, --controller URL  Clash/Mihomo controller URL.
                       Default: ${DEFAULT_CONTROLLER}
                       Env: CLASH_CONTROLLER_URL
  -g, --group NAME      Proxy group to read and switch.
                       Default: ${DEFAULT_GROUP}
                       Env: CLASH_PROXY_GROUP
  -s, --secret SECRET   Controller API secret.
                       Env: CLASH_API_SECRET
      --json            Print list output as JSON.
  -h, --help            Show this help.

Examples:
  clash-switch.ts list
  clash-switch.ts list Nexitally
  clash-switch.ts switch "Hong Kong 01"
  clash-switch.ts "Japan 01"
  CLASH_PROXY_GROUP=Nexitally clash-switch.ts
`;

function mainArgs(): Options {
  const args = process.argv.slice(2);
  const positionals: string[] = [];
  let controller = process.env.CLASH_CONTROLLER_URL || DEFAULT_CONTROLLER;
  let group = process.env.CLASH_PROXY_GROUP || DEFAULT_GROUP;
  let secret = process.env.CLASH_API_SECRET || undefined;
  let json = false;

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];

    if (arg === "--") {
      positionals.push(...args.slice(i + 1));
      break;
    }

    if (arg === "-h" || arg === "--help") {
      process.stdout.write(HELP);
      process.exit(0);
    }

    if (arg === "--json") {
      json = true;
      continue;
    }

    if (arg === "-c" || arg === "--controller") {
      controller = requireValue(args, i, arg);
      i += 1;
      continue;
    }

    if (arg === "-g" || arg === "--group") {
      group = requireValue(args, i, arg);
      i += 1;
      continue;
    }

    if (arg === "-s" || arg === "--secret") {
      secret = requireValue(args, i, arg);
      i += 1;
      continue;
    }

    if (arg.startsWith("--controller=")) {
      controller = arg.slice("--controller=".length);
      continue;
    }

    if (arg.startsWith("--group=")) {
      group = arg.slice("--group=".length);
      continue;
    }

    if (arg.startsWith("--secret=")) {
      secret = arg.slice("--secret=".length);
      continue;
    }

    if (arg.startsWith("-")) {
      throw new Error(`Unknown option: ${arg}`);
    }

    positionals.push(arg);
  }

  if (positionals.length === 0) {
    return { command: "interactive", controller, group, secret, json };
  }

  const [command, ...rest] = positionals;

  if (command === "list") {
    if (rest.length > 0) {
      group = rest.join(" ");
    }
    return { command: "list", controller, group, secret, json };
  }

  if (command === "switch" || command === "set") {
    if (rest.length === 0) {
      throw new Error(`${command} requires a node name`);
    }
    return { command: "switch", controller, group, secret, json, node: rest.join(" ") };
  }

  return { command: "switch", controller, group, secret, json, node: positionals.join(" ") };
}

function requireValue(args: string[], index: number, option: string): string {
  const value = args[index + 1];
  if (!value || value.startsWith("-")) {
    throw new Error(`${option} requires a value`);
  }
  return value;
}

async function run(): Promise<void> {
  const options = mainArgs();
  const group = await getGroupState(options);

  if (options.command === "list") {
    printList(options, group);
    return;
  }

  if (options.command === "switch") {
    const target = resolveNode(options.node || "", group.all);
    await switchNode(options, target, group.now);
    return;
  }

  const selected = await selectNode(options, group);
  await switchNode(options, selected, group.now);
}

async function getGroupState(options: Options): Promise<GroupState> {
  const data = await requestJson<{ proxies?: unknown }>(options, "GET", "/proxies");
  if (!isRecord(data.proxies)) {
    throw new Error("Controller response does not contain a proxies object");
  }

  const rawGroup = data.proxies[options.group];
  if (!isRecord(rawGroup)) {
    const groups = Object.entries(data.proxies)
      .filter(([, value]) => isRecord(value) && Array.isArray(value.all))
      .map(([name]) => name)
      .sort();
    const hint = groups.length > 0 ? ` Available groups: ${groups.join(", ")}` : "";
    throw new Error(`Proxy group not found: ${options.group}.${hint}`);
  }

  const proxyGroup = rawGroup as ProxyGroup;
  if (!Array.isArray(proxyGroup.all) || !proxyGroup.all.every((value) => typeof value === "string")) {
    throw new Error(`Proxy group ${options.group} does not expose an all[] node list`);
  }

  return {
    all: proxyGroup.all,
    now: typeof proxyGroup.now === "string" ? proxyGroup.now : undefined,
  };
}

async function requestJson<T>(options: Options, method: string, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = {};
  if (options.secret) {
    headers.Authorization = `Bearer ${options.secret}`;
  }
  if (body !== undefined) {
    headers["Content-Type"] = "application/json";
  }

  const response = await fetch(controllerPath(options.controller, path), {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await response.text();

  if (!response.ok) {
    const detail = text.trim() ? `: ${text.trim()}` : "";
    throw new Error(`${method} ${path} failed with HTTP ${response.status}${detail}`);
  }

  if (!text.trim()) {
    return undefined as T;
  }

  try {
    return JSON.parse(text) as T;
  } catch (error) {
    throw new Error(`${method} ${path} returned invalid JSON: ${(error as Error).message}`);
  }
}

function controllerPath(controller: string, path: string): URL {
  const base = controller.includes("://") ? controller : `http://${controller}`;
  const url = new URL(base);
  const prefix = url.pathname.replace(/\/+$/, "");
  url.pathname = `${prefix}${path}`;
  return url;
}

function printList(options: Options, group: GroupState): void {
  if (options.json) {
    process.stdout.write(`${JSON.stringify({ group: options.group, current: group.now, nodes: group.all }, null, 2)}\n`);
    return;
  }

  for (const node of group.all) {
    const marker = node === group.now ? "*" : " ";
    process.stdout.write(`${marker} ${node}\n`);
  }
}

function resolveNode(input: string, nodes: string[]): string {
  const wanted = input.trim();
  if (!wanted) {
    throw new Error("Node name cannot be empty");
  }

  if (nodes.includes(wanted)) {
    return wanted;
  }

  const lowerWanted = wanted.toLowerCase();
  const exactCaseInsensitive = nodes.filter((node) => node.toLowerCase() === lowerWanted);
  if (exactCaseInsensitive.length === 1) {
    return exactCaseInsensitive[0];
  }

  const partial = nodes.filter((node) => node.toLowerCase().includes(lowerWanted));
  if (partial.length === 1) {
    return partial[0];
  }

  if (partial.length > 1) {
    throw new Error(`Node name is ambiguous: ${wanted}. Matches: ${partial.slice(0, 10).join(", ")}`);
  }

  throw new Error(`Node not found in group: ${wanted}`);
}

async function switchNode(options: Options, target: string, previous?: string): Promise<void> {
  await requestJson(options, "PUT", `/proxies/${encodeURIComponent(options.group)}`, { name: target });

  if (previous === target) {
    process.stdout.write(`${options.group} already uses ${target}\n`);
    return;
  }

  const before = previous ? `${previous} -> ` : "";
  process.stdout.write(`Switched ${options.group}: ${before}${target}\n`);
}

async function selectNode(options: Options, group: GroupState): Promise<string> {
  if (!process.stdin.isTTY || !process.stdout.isTTY) {
    throw new Error("Interactive selection requires a TTY; pass a node name instead");
  }

  const stdin = process.stdin;
  const stdout = process.stdout;
  let query = "";
  let index = Math.max(0, group.all.findIndex((node) => node === group.now));

  stdin.setRawMode(true);
  stdin.resume();
  stdin.setEncoding("utf8");
  stdout.write("\x1b[?1049h\x1b[?25l");

  try {
    while (true) {
      const filtered = filterNodes(group.all, query);
      if (filtered.length === 0) {
        index = 0;
      } else if (index >= filtered.length) {
        index = filtered.length - 1;
      }

      drawSelector(stdout, options, group, filtered, query, index);
      const key = await readKey(stdin);

      if (key === "ctrl-c" || key === "escape") {
        throw new Error("Selection cancelled");
      }

      if (key === "enter") {
        if (filtered.length === 0) {
          continue;
        }
        return filtered[index];
      }

      if (key === "up") {
        index = Math.max(0, index - 1);
        continue;
      }

      if (key === "down") {
        index = Math.min(Math.max(0, filtered.length - 1), index + 1);
        continue;
      }

      if (key === "backspace") {
        query = Array.from(query).slice(0, -1).join("");
        index = 0;
        continue;
      }

      if (key.startsWith("text:")) {
        query += key.slice("text:".length);
        index = 0;
      }
    }
  } finally {
    stdout.write("\x1b[?25h\x1b[?1049l");
    stdin.setRawMode(false);
    stdin.pause();
  }
}

function filterNodes(nodes: string[], query: string): string[] {
  const trimmed = query.trim().toLowerCase();
  if (!trimmed) {
    return nodes;
  }
  return nodes.filter((node) => node.toLowerCase().includes(trimmed));
}

function drawSelector(
  stdout: NodeJS.WriteStream,
  options: Options,
  group: GroupState,
  nodes: string[],
  query: string,
  index: number,
): void {
  const terminalRows = typeof process.stdout.rows === "number" ? process.stdout.rows : 18;
  const maxRows = Math.min(12, Math.max(1, terminalRows - 6));
  const start = Math.max(0, Math.min(index - Math.floor(maxRows / 2), nodes.length - maxRows));
  const visible = nodes.slice(start, start + maxRows);
  const lines = [
    `Select Clash node for ${options.group}`,
    `Controller: ${options.controller}`,
    "Type to filter. Use arrows/Ctrl-N/Ctrl-P, Enter to switch, Esc/Ctrl-C to cancel.",
    `Filter: ${query}`,
    "",
  ];

  if (visible.length === 0) {
    lines.push("  No matches");
  } else {
    visible.forEach((node, offset) => {
      const absolute = start + offset;
      const cursor = absolute === index ? ">" : " ";
      const current = node === group.now ? "*" : " ";
      lines.push(`${cursor} ${current} ${node}`);
    });
  }

  if (nodes.length > visible.length) {
    lines.push("");
    lines.push(`Showing ${start + 1}-${start + visible.length} of ${nodes.length}`);
  }

  stdout.write(`\x1b[H\x1b[J${lines.join("\n")}`);
}

function readKey(stdin: NodeJS.ReadStream): Promise<string> {
  return new Promise((resolve) => {
    stdin.once("data", (chunk: string) => {
      resolve(parseKey(chunk));
    });
  });
}

function parseKey(input: string): string {
  if (input === "\u0003") {
    return "ctrl-c";
  }
  if (input === "\r" || input === "\n") {
    return "enter";
  }
  if (input === "\u001b" || input === "\u001b[") {
    return "escape";
  }
  if (input === "\u001b[A" || input === "\u001bOA" || input === "\u0010") {
    return "up";
  }
  if (input === "\u001b[B" || input === "\u001bOB" || input === "\u000e") {
    return "down";
  }
  if (input === "\u007f" || input === "\b" || input === "\u001b[3~") {
    return "backspace";
  }

  const printable = Array.from(input).filter((char) => {
    const codePoint = char.codePointAt(0) || 0;
    return codePoint >= 0x20 && codePoint !== 0x7f && !char.startsWith("\u001b");
  });

  if (printable.length > 0) {
    return `text:${printable.join("")}`;
  }

  return "unknown";
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

run().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  process.stderr.write(`clash-switch: ${message}\n`);
  process.exitCode = 1;
});
