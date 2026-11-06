const fs = require('fs');
const path = require('path');

function validateLua(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split('\n');

  // Strip block comments --[[ ... ]] and line comments -- ...
  // Strip string literals "..." and '...' and [[ ... ]]
  let stripped = '';
  let inBlockComment = false;
  let inBlockString = false;
  let inLineComment = false;
  let inString = null; // '"' or "'"

  let i = 0;
  while (i < content.length) {
    if (inBlockComment) {
      if (content.substr(i, 2) === ']]') {
        inBlockComment = false;
        i += 2;
        stripped += '  ';
      } else {
        stripped += content[i] === '\n' ? '\n' : ' ';
        i++;
      }
    } else if (inBlockString) {
      if (content.substr(i, 2) === ']]') {
        inBlockString = false;
        i += 2;
        stripped += '  ';
      } else {
        stripped += content[i] === '\n' ? '\n' : ' ';
        i++;
      }
    } else if (inLineComment) {
      if (content[i] === '\n') {
        inLineComment = false;
        stripped += '\n';
      } else {
        stripped += ' ';
      }
      i++;
    } else if (inString) {
      if (content[i] === '\\') {
        stripped += '  ';
        i += 2;
      } else if (content[i] === inString) {
        inString = null;
        stripped += ' ';
        i++;
      } else {
        stripped += content[i] === '\n' ? '\n' : ' ';
        i++;
      }
    } else {
      if (content.substr(i, 4) === '--[[') {
        inBlockComment = true;
        stripped += '    ';
        i += 4;
      } else if (content.substr(i, 2) === '--') {
        inLineComment = true;
        stripped += '  ';
        i += 2;
      } else if (content.substr(i, 2) === '[[') {
        inBlockString = true;
        stripped += '  ';
        i += 2;
      } else if (content[i] === '"' || content[i] === "'") {
        inString = content[i];
        stripped += ' ';
        i++;
      } else {
        stripped += content[i];
        i++;
      }
    }
  }

  // Tokenize words and symbols
  const tokens = [];
  const regex = /([a-zA-Z_][a-zA-Z0-9_]*|[0-9]+|==|~=|<=|>=|\.\.|\.|[{}()[\],;=+\-*/%^#])/g;
  let match;
  while ((match = regex.exec(stripped)) !== null) {
    // find line number
    const lineNum = content.substr(0, match.index).split('\n').length;
    tokens.push({ text: match[1], line: lineNum, index: match.index });
  }

  const stack = [];
  let parenDepth = 0;
  let bracketDepth = 0;
  let braceDepth = 0;

  for (let t = 0; t < tokens.length; t++) {
    const tok = tokens[t];
    const text = tok.text;

    if (text === '(') parenDepth++;
    else if (text === ')') {
      parenDepth--;
      if (parenDepth < 0) return { ok: false, error: `Unmatched ')' at line ${tok.line}` };
    } else if (text === '[') bracketDepth++;
    else if (text === ']') {
      bracketDepth--;
      if (bracketDepth < 0) return { ok: false, error: `Unmatched ']' at line ${tok.line}` };
    } else if (text === '{') braceDepth++;
    else if (text === '}') {
      braceDepth--;
      if (braceDepth < 0) return { ok: false, error: `Unmatched '}' at line ${tok.line}` };
    } else if (text === 'function') {
      stack.push({ text: 'function', line: tok.line });
    } else if (text === 'do') {
      stack.push({ text: 'do', line: tok.line });
    } else if (text === 'if') {
      stack.push({ text: 'if', line: tok.line });
    } else if (text === 'repeat') {
      stack.push({ text: 'repeat', line: tok.line });
    } else if (text === 'until') {
      const top = stack.pop();
      if (!top || top.text !== 'repeat') {
        return { ok: false, error: `Unexpected 'until' at line ${tok.line}, top was ${top ? top.text : 'empty'}` };
      }
    } else if (text === 'end') {
      const top = stack.pop();
      if (!top || (top.text !== 'function' && top.text !== 'do' && top.text !== 'if')) {
        return { ok: false, error: `Unexpected 'end' at line ${tok.line}, top was ${top ? top.text : 'empty'}` };
      }
    }
  }

  if (parenDepth !== 0) return { ok: false, error: `Unclosed '(' (${parenDepth} open)` };
  if (bracketDepth !== 0) return { ok: false, error: `Unclosed '[' (${bracketDepth} open)` };
  if (braceDepth !== 0) return { ok: false, error: `Unclosed '{' (${braceDepth} open)` };
  if (stack.length > 0) {
    const unclosed = stack.map(s => `${s.text} at line ${s.line}`).join(', ');
    return { ok: false, error: `Unclosed blocks: ${unclosed}` };
  }

  return { ok: true, tokensCount: tokens.length };
}

const files = [
  'main/modules/sound.lua',
  'main/modules/talents.lua',
  'main/modules/battle_state.lua',
  'main/modules/i18n.lua',
  'main/modules/poki.lua',
  'main/gui/main.gui_script',
  'main/entities/battle_manager/battle_manager.script',
  'main/entities/bunch_controller/bunch_controller.script',
];

let allOk = true;
for (const file of files) {
  const fullPath = path.resolve(file);
  if (!fs.existsSync(fullPath)) {
    console.error(`File not found: ${file}`);
    allOk = false;
    continue;
  }
  const res = validateLua(fullPath);
  if (res.ok) {
    console.log(`PASS: ${file} (${res.tokensCount} tokens)`);
  } else {
    console.error(`FAIL: ${file} -> ${res.error}`);
    allOk = false;
  }
}

if (!allOk) process.exit(1);
console.log('All checked Lua files have valid balanced blocks & delimiters!');
