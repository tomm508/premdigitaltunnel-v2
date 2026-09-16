const fs = require('fs');
const file = '/app/applet/src/App.tsx';
let content = fs.readFileSync(file, 'utf8');

// Ensure React is imported
if (!content.includes("import React")) {
    content = "import React from 'react';\n" + content;
}

fs.writeFileSync(file, content);
console.log("Patched successfully");
