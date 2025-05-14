# Contributing to BIRD-SQL Mini-Dev

Thank you for your interest in contributing to the BIRD-SQL Mini-Dev project! This document provides guidelines for contributions.

## Code of Conduct

- Please be respectful and considerate of others
- Focus on constructive feedback and suggestions
- Aim to improve the project for everyone

## How to Contribute

### Submitting Issues

If you find bugs or have feature requests, please create an issue with:

1. A clear title and description
2. Steps to reproduce the issue
3. Expected vs. actual behavior
4. Screenshots (if applicable)
5. Environment details (OS, Python version, database versions)

### Pull Requests

For code contributions:

1. Fork the repository
2. Create a branch with a descriptive name
3. Make focused changes addressing a specific issue
4. Add or update tests for your changes
5. Ensure all tests pass
6. Submit a pull request referencing any related issues

### Code Style

- Follow PEP 8 for Python code
- Use meaningful variable and function names
- Include docstrings and comments where necessary
- Keep functions small and focused on a single task

### Testing

- Add tests for new features
- Verify that existing tests continue to pass
- Test with all supported SQL dialects when making changes to database interactions

## Development Setup

1. Create a virtual environment
2. Install development dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Run tests to verify your setup:
   ```bash
   python check_setup.py
   ```

## License

By contributing to this project, you agree that your contributions will be licensed under the same license as the project (Creative Commons Attribution-ShareAlike 4.0 International License).

## Contact

For questions or discussions, please open an issue or contact the maintainers. 