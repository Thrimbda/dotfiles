function stringValue(value) {
    return typeof value === "string" ? value.trim() : "";
}

function normalizedAddress(device) {
    return stringValue(device && device.address).toLowerCase();
}

function hasHumanName(device) {
    if (stringValue(device && device.deviceName) !== "")
        return true;

    const alias = stringValue(device && device.name);
    const address = normalizedAddress(device);
    return alias !== "" && alias.toLowerCase() !== address;
}

function isPrimaryCandidate(device) {
    return !!(device && (device.connected || device.paired || device.bonded || hasHumanName(device)));
}

function sortLabel(device) {
    const alias = stringValue(device && device.name);
    const address = normalizedAddress(device);
    if (alias !== "" && alias.toLowerCase() !== address)
        return alias;

    const deviceName = stringValue(device && device.deviceName);
    return deviceName !== "" ? deviceName : stringValue(device && device.address);
}

function compareText(left, right) {
    const a = stringValue(left).toLowerCase();
    const b = stringValue(right).toLowerCase();
    return a < b ? -1 : (a > b ? 1 : 0);
}

function compareDevices(a, b) {
    const connected = Number(!!(b && b.connected)) - Number(!!(a && a.connected));
    if (connected !== 0)
        return connected;

    const pairedA = !!(a && (a.paired || a.bonded));
    const pairedB = !!(b && (b.paired || b.bonded));
    const paired = Number(pairedB) - Number(pairedA);
    if (paired !== 0)
        return paired;

    const named = Number(hasHumanName(b)) - Number(hasHumanName(a));
    if (named !== 0)
        return named;

    const label = compareText(sortLabel(a), sortLabel(b));
    return label !== 0 ? label : compareText(normalizedAddress(a), normalizedAddress(b));
}

function primaryDevices(devices, limit) {
    const maximum = limit === undefined ? 5 : Math.max(0, Number(limit));
    const decorated = [];

    for (let index = 0; index < devices.length; ++index) {
        const device = devices[index];
        if (isPrimaryCandidate(device))
            decorated.push({ device, index });
    }

    decorated.sort((left, right) => compareDevices(left.device, right.device) || left.index - right.index);
    return decorated.slice(0, maximum).map(entry => entry.device);
}
