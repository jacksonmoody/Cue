#!/usr/bin/env node

var crypto = require("crypto");

// Generate a 32-byte (256-bit) key and encode as base64
var key = crypto.randomBytes(32).toString("base64");

console.log("Generated Encryption Key:");
console.log("==========================================");
console.log(key);
console.log("==========================================");
