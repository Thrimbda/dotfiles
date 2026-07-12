const fs = require("fs");
const vm = require("vm");

const [policyPath, pairingPath] = process.argv.slice(2);
if (!policyPath || !pairingPath)
    throw new Error("usage: policy-test POLICY_JS BLUETOOTH_PAIRING_QML");

const context = {};
vm.createContext(context);
vm.runInContext(fs.readFileSync(policyPath, "utf8"), context, { filename: policyPath });

const requiredFunctions = ["hasHumanName", "isPrimaryCandidate", "sortLabel", "compareDevices", "primaryDevices"];
for (const name of requiredFunctions) {
    if (typeof context[name] !== "function")
        throw new Error(`missing policy function: ${name}`);
}

function device(id, values = {}) {
    return {
        id,
        address: values.address ?? `00:00:00:00:00:${id}`,
        name: values.name ?? values.address ?? `00:00:00:00:00:${id}`,
        deviceName: values.deviceName ?? "",
        connected: values.connected ?? false,
        paired: values.paired ?? false,
        bonded: values.bonded ?? false,
    };
}

function assert(condition, message) {
    if (!condition)
        throw new Error(message);
}

assert(context.hasHumanName(device("01", { deviceName: "Keyboard" })), "BlueZ Name should be human");
assert(context.hasHumanName(device("02", { name: "  Custom alias  " })), "custom Alias should be human");
assert(!context.hasHumanName(device("03", {
    address: "AA:BB:CC:DD:EE:FF",
    name: "aa:bb:cc:dd:ee:ff",
})), "Alias equal to Address should be anonymous");
assert(!context.hasHumanName(device("04", { name: "   ", deviceName: "\t" })), "whitespace should be anonymous");

const input = [
    device("90"),
    device("30", { name: "Connected named", connected: true }),
    device("10", { connected: true }),
    device("40", { name: "Paired named", paired: true }),
    device("20", { paired: true }),
    device("50", { bonded: true }),
    device("60", { name: "Alpha" }),
    device("70", { deviceName: "Zulu" }),
];
const snapshot = input.slice();
const result = context.primaryDevices(input);

assert(result.length === 5, "primary popout must be capped at five");
assert(result.map(d => d.id).join(",") === "30,10,40,20,50", "unexpected primary device order");
assert(input.every((entry, index) => entry === snapshot[index]), "policy mutated its input array");
assert(!result.some(d => d.id === "90"), "anonymous noise occupied the primary popout");
assert(context.isPrimaryCandidate(device("80", { connected: true })), "anonymous connected device was removed");
assert(context.isPrimaryCandidate(device("81", { paired: true })), "anonymous paired device was removed");
assert(context.isPrimaryCandidate(device("82", { bonded: true })), "anonymous bonded device was removed");

const addressTie = [
    device("b", { address: "00:00:00:00:00:0B", name: "Same" }),
    device("a", { address: "00:00:00:00:00:0A", name: "same" }),
];
assert(context.primaryDevices(addressTie).map(d => d.id).join(",") === "a,b", "address tie-break is unstable");

const exactTie = [device("first", { name: "Same", address: "01" }), device("second", { name: "same", address: "01" })];
assert(context.primaryDevices(exactTie).map(d => d.id).join(",") === "first,second", "input-index tie-break is unstable");

const pairing = fs.readFileSync(pairingPath, "utf8");
assert(pairing.includes("filter(d => !d.bonded)"), "pairing page no longer retains unbonded devices");
assert(!pairing.includes("BluetoothPolicy"), "primary policy leaked into the full pairing page");
assert(!/\.slice\s*\(\s*0\s*,\s*5\s*\)/.test(pairing), "pairing page was truncated to five devices");
assert(!pairing.includes("hasHumanName") && !pairing.includes("primaryDevices"), "pairing page filters anonymous devices");
