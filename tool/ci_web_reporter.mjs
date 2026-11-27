// Supplement Node's normal TAP reporter with actionable GitHub annotations.
// Report failures only; Node still owns the test run and its original exit code.
import { inspect } from 'node:util';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const escapeData = value => String(value).replaceAll('%', '%25').replaceAll('\r', '%0D').replaceAll('\n', '%0A');
const escapeProperty = value => escapeData(value).replaceAll(':', '%3A').replaceAll(',', '%2C');

export default async function* githubFailures(events) {
  for await (const { type, data } of events) {
    if (type !== 'test:fail') continue;
    const properties = ['title=Browser regression'];
    if (typeof data.file === 'string') {
      const filename = data.file.startsWith('file:') ? fileURLToPath(data.file) : data.file;
      const relative = path.relative(process.cwd(), filename);
      if (relative && relative !== '..' && !relative.startsWith(`..${path.sep}`) && !path.isAbsolute(relative)) {
        properties.push(`file=${escapeProperty(relative)}`);
        if (Number.isSafeInteger(data.line) && data.line > 0) properties.push(`line=${data.line}`);
      }
    }
    const details = inspect(data.details?.error, { depth: 6, colors: false, breakLength: 120 });
    const message = `${data.name}\n${details}`.slice(0, 16000);
    yield `::error ${properties.join(',')}::${escapeData(message)}\n`;
  }
}
