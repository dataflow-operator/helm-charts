const RELEASE_COMMIT_RE = /^chore\(release\):/i;

const NOOP_LOGGER = { log() {}, error() {} };

function listCommits(fromTag, logger = NOOP_LOGGER) {
  const args = ['log', '--pretty=format:%h %s', '--no-merges', '--reverse'];
  if (fromTag) {
    args.push(`${fromTag}..HEAD`);
  }

  let output;
  try {
    output = require('child_process')
      .execFileSync('git', args, { encoding: 'utf-8' })
      .trim();
  } catch (error) {
    const stderr = error.stderr ? error.stderr.toString().trim() : '';
    const details = stderr || error.message;
    logger.error(`Failed to run "git ${args.join(' ')}": ${details}`);
    throw new Error(`Unable to generate release notes: ${details}`, { cause: error });
  }

  if (!output) {
    return [];
  }

  return output
    .split('\n')
    .filter((line) => {
      const message = line.replace(/^[0-9a-f]+\s+/, '');
      return message.length > 0 && !RELEASE_COMMIT_RE.test(message);
    });
}

async function generateNotes(_pluginConfig, context) {
  const fromTag = context.lastRelease?.gitTag;
  const commits = listCommits(fromTag, context.logger);

  if (commits.length === 0) {
    return 'No user-facing commits in this release.';
  }

  return ['## Commits', '', ...commits.map((commit) => `- ${commit}`)].join('\n');
}

module.exports = { generateNotes, listCommits, RELEASE_COMMIT_RE };
