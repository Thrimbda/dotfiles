const fs = require("fs");
const path = require("path");

const [source, pluginQmltypesPath] = process.argv.slice(2);
if (!source || !pluginQmltypesPath)
    throw new Error("usage: caelestia-lock-dpms-patch-test CAELESTIA_SOURCE PLUGIN_QMLTYPES");

function assert(condition, message) {
    if (!condition)
        throw new Error(message);
}

function read(relativePath) {
    return fs.readFileSync(path.join(source, relativePath), "utf8");
}

function assertMatch(contents, expression, message) {
    assert(expression.test(contents), message);
}

const config = read("plugin/src/Caelestia/Config/generalconfig.hpp");
const idleMonitors = read("modules/IdleMonitors.qml");
const pluginQmltypes = fs.readFileSync(pluginQmltypesPath, "utf8");

assert(config.includes("CONFIG_GLOBAL_PROPERTY(int, lockDpmsTimeout, 0)"),
    "lock DPMS timeout config property is missing");
assertMatch(pluginQmltypes,
    /name: "caelestia::config::GeneralIdle"[\s\S]*?Property \{\s*name: "lockDpmsTimeout"\s*type: "int"/,
    "lock DPMS timeout is not registered by the plugin");
assertMatch(idleMonitors, /property int lockEpoch:\s*0/, "lock epoch state is missing");
assertMatch(idleMonitors, /property Timer activeLockDpmsTimer:\s*null/, "active timer state is missing");
assertMatch(idleMonitors, /property int dpmsOffEpoch:\s*-1/, "DPMS-off epoch state is missing");
assertMatch(idleMonitors,
    /target:\s*root\.lock\.lock\s*function onLockedChanged\(\): void \{\s*root\.handleLockStateChanged\(\);/s,
    "lock state observer is missing");
assertMatch(idleMonitors, /GlobalConfig\.general\.idle\.lockDpmsTimeout\s*<=\s*0/,
    "nonpositive lock DPMS timeout does not disable the feature");
assertMatch(idleMonitors, /if \(activeLockDpmsTimer \|\| dpmsOffEpoch === lockEpoch\)\s*return;/s,
    "repeated lock requests can create or restart a timer");
assertMatch(idleMonitors,
    /lockDpmsTimerComponent\.createObject\(root,\s*\{\s*epoch:\s*lockEpoch,\s*interval:\s*GlobalConfig\.general\.idle\.lockDpmsTimeout\s*\*\s*1000,/s,
    "per-epoch timer creation is missing");
assertMatch(idleMonitors, /required property int epoch/, "timer epoch is not immutable construction state");
assert(!/\bepoch\s*=(?!=)/.test(idleMonitors), "timer epoch is reassigned after construction");
assertMatch(idleMonitors, /repeat:\s*false/, "lock DPMS timer is not one-shot");
assertMatch(idleMonitors,
    /if \(root\.lock\.lock\.locked\s*&& epoch === root\.lockEpoch\s*&& timer === root\.activeLockDpmsTimer\) \{\s*root\.handleIdleAction\("dpms off"\);\s*root\.dpmsOffEpoch = epoch;/s,
    "timer expiry lacks lock, epoch, identity, or DPMS-off wiring");
assertMatch(idleMonitors, /timer\.stop\(\);\s*timer\.destroy\(\);/s,
    "unlock does not stop and destroy the active timer");
assertMatch(idleMonitors,
    /const previousLockEpoch = lockEpoch;\s*lockEpoch \+= 1;\s*const dpmsWasOff = dpmsOffEpoch === previousLockEpoch;\s*clearActiveLockDpmsTimer\(\);\s*dpmsOffEpoch = -1;\s*if \(dpmsWasOff\)\s*handleIdleAction\("dpms on"\);/s,
    "unlock does not invalidate the epoch, clear wake state, and restore timer-owned DPMS");
assertMatch(idleMonitors,
    /id:\s*lockDpmsWakeMonitor\s*enabled:\s*root\.lock\.lock\.locked\s*&& root\.dpmsOffEpoch === root\.lockEpoch\s*timeout:\s*0\s*respectInhibitors:\s*false/s,
    "timer-owned DPMS wake monitor is missing or incorrectly enabled");
assertMatch(idleMonitors,
    /if \(!isIdle\s*&& root\.lock\.lock\.locked\s*&& root\.dpmsOffEpoch === root\.lockEpoch\) \{\s*root\.handleIdleAction\("dpms on"\);\s*root\.dpmsOffEpoch = -1;/s,
    "wake monitor does not preserve the lock-scoped DPMS wake state");

const wakeStart = idleMonitors.indexOf("id: lockDpmsWakeMonitor");
const wakeEnd = idleMonitors.indexOf("\n    Variants {", wakeStart);
const wakeMonitor = idleMonitors.slice(wakeStart, wakeEnd);
assert(wakeStart >= 0 && wakeEnd >= 0, "wake monitor boundaries are missing");
assert(!wakeMonitor.includes("locked ="), "wake monitor changes lock state");
assert(!wakeMonitor.includes("lockDpmsTimerComponent"), "wake monitor re-arms the DPMS timer");
