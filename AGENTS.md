# Repository Issue Workflow

For every GitHub issue, follow this sequence in order:

1. Pull the issue from GitHub and read its current description, acceptance criteria, labels, dependencies, and relevant discussion.
2. Investigate and audit the repository to confirm the problem, its cause, affected code, implementation scope, risks, and appropriate verification.
3. Before changing any implementation files, explain the issue to the repository owner in simple, everyday language. Avoid complex technical jargon and do not assume the owner has specialist technical knowledge. If a technical term cannot be avoided, define it briefly in plain language. Explain:
   - the problem that is about to be fixed;
   - why it occurs and why it matters;
   - the proposed implementation;
   - the files or systems likely to be affected; and
   - the tests or checks that will verify the fix.
4. Wait for the repository owner's explicit approval before implementing the issue.
5. After approval, implement the issue on a dedicated issue branch and verify the result. Keep the change limited to the approved issue scope.
6. After implementation and verification, summarize what changed and open a pull request against the repository's main or master branch for the owner to review and merge.

Never merge the pull request on the owner's behalf, and never commit issue work directly to the main or master branch.
