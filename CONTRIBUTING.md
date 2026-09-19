# Contributing to WhatsApp Desktop

Thanks for your interest in contributing to WhatsApp Desktop!

## Getting Started

1. Fork this repository.
2. Clone your fork:

   ```bash
   git clone https://github.com/YOUR_USERNAME/Whatsapp-Dekstop.git
   cd Whatsapp-Dekstop
   ```

3. Create a feature branch:

   ```bash
   git checkout -b fix/your-change
   ```

4. Install the required dependencies for your platform.

## Supported Platforms

WhatsApp Desktop aims to support:

- macOS
- Linux
- Windows

Some features may behave differently depending on the operating system and available system dependencies.

## Development

Build the project:

```bash
go build ./...
```

Run the tests:

```bash
go test ./...
```

If the project uses vendored dependencies:

```bash
GOFLAGS=-mod=vendor go test ./...
```

## Project Structure

Before making changes, take a moment to understand the existing project structure and identify the relevant package or component.

Keep changes focused on the specific problem being solved.

## Code Guidelines

- Follow the existing Go style and project structure.
- Keep changes focused and easy to review.
- Avoid unrelated formatting changes.
- Use clear and descriptive names.
- Add comments only when they improve clarity.
- Do not commit secrets, credentials, or personal data.
- Update documentation when setup instructions or behavior change.

## Platform-Specific Changes

Some features depend on platform-specific libraries and system APIs.

When making platform-specific changes, document:

- The affected operating system.
- Required system dependencies.
- Any known limitations.
- How the change was tested.

## UI Changes

For user interface changes:

- Keep the existing visual style consistent.
- Test the change on the affected platform.
- Include screenshots or screen recordings in the pull request.
- Check both normal and edge-case states.
- Consider different window sizes and screen resolutions.

## Testing

Before opening a pull request, make sure that:

- The project builds successfully.
- Existing tests pass.
- New behavior has been tested manually.
- Platform-specific behavior has been checked when applicable.
- No unrelated functionality is broken.

## Pull Requests

Please include the following information:

- A clear description of the problem and solution.
- Steps to reproduce or test the change.
- Screenshots or recordings for UI changes.
- A list of affected platforms.
- Any known limitations or follow-up work.

### Pull Request Checklist

- [ ] The project builds successfully.
- [ ] Existing tests pass.
- [ ] New behavior has been tested manually.
- [ ] UI changes include screenshots or recordings.
- [ ] No secrets or personal data are included.
- [ ] Documentation has been updated when necessary.
- [ ] The pull request describes the problem and solution clearly.
- [ ] The changes are focused and ready for review.

## Commit Messages

Use clear and descriptive commit messages:

```text
fix: improve document download handling
feat: add notification preferences
docs: update Linux setup instructions
refactor: simplify message rendering
test: add download handling tests
```

## Bug Reports

When reporting a bug, include:

- Operating system and version.
- Application version or commit.
- Steps to reproduce the issue.
- Expected behavior.
- Actual behavior.
- Relevant logs or screenshots.
- Whether the issue can be reproduced consistently.

## Troubleshooting

If the application does not build:

1. Confirm that the required Go version is installed.
2. Confirm that all platform dependencies are available.
3. Try building with vendored dependencies:

   ```bash
   GOFLAGS=-mod=vendor go build ./...
   ```

4. Check the complete error message.
5. Include relevant logs when requesting help.

## Security Issues

Please do not disclose security vulnerabilities in public issues.

Contact the maintainers privately with the details so the issue can be investigated responsibly.

## Code of Conduct

Please be respectful and constructive when participating in discussions, reviewing code, reporting issues, or submitting pull requests.

Harassment, discrimination, personal attacks, and disruptive behavior are not tolerated.

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project.

## Thank You

Thank you for helping improve WhatsApp Desktop!
