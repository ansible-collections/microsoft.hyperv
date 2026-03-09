# Contributing to Microsoft Hyper-V Collection

Thank you for your interest in contributing to the Microsoft Hyper-V Collection! This document provides guidelines for contributing to this project.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally
3. **Create a feature branch** for your contribution
4. **Make your changes** following our guidelines
5. **Test your changes** thoroughly
6. **Submit a pull request**

## Development Environment Setup

### Requirements
- Python 3.9 or later
- Ansible 2.14 or later
- Access to a Windows Server with Hyper-V for testing
- PowerShell 5.1 or later on the Hyper-V host

### Setup Steps
```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/microsoft.hyperv.git
cd microsoft.hyperv

# Install development dependencies
pip install -r requirements-dev.txt

# Set up pre-commit hooks (if available)
pre-commit install
```

## Types of Contributions

### Module Development
We are actively developing modules as outlined in Epic [ACA-4728](https://issues.redhat.com/browse/ACA-4728). See [ROADMAP.md](ROADMAP.md) for the complete list of planned modules.

To contribute a new module:
1. Check the roadmap to see if the module is planned
2. Comment on the corresponding Jira task to claim it
3. Follow the module development guidelines below

### Bug Fixes
Found a bug? Please:
1. Check if an issue already exists
2. If not, create a new issue with detailed information
3. Submit a PR with the fix

### Documentation
Documentation improvements are always welcome:
- Module documentation (EXAMPLES, RETURN, parameter descriptions)
- Collection-level documentation (README, guides, tutorials)
- Code comments for complex logic

## Module Development Guidelines

### Module Structure
```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2026, Ansible Project
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: hv_example
short_description: Short description of what the module does
description:
  - Longer description of the module
  - Can be multiple paragraphs
options:
  name:
    description:
      - Name of the resource
    type: str
    required: true
'''

EXAMPLES = r'''
- name: Example task
  microsoft.hyperv.hv_example:
    name: example_resource
    state: present
'''

RETURN = r'''
# Document return values
'''
```

### Module Requirements
1. **Documentation**: Complete DOCUMENTATION, EXAMPLES, and RETURN sections
2. **Error Handling**: Proper exception handling with meaningful error messages
3. **Idempotency**: Modules must be idempotent (safe to run multiple times)
4. **Check Mode**: Support for `--check` mode
5. **Changed Status**: Accurately report when changes are made
6. **Testing**: Include unit tests and integration tests

### PowerShell Integration
Most modules will interact with Hyper-V via PowerShell cmdlets:
- Use the `ansible.module_utils.powershell` utilities
- Handle PowerShell errors appropriately
- Test on both Windows Server 2016+ versions

## Testing

### Unit Tests
```bash
# Run unit tests
ansible-test units --python 3.9
```

### Integration Tests
```bash
# Run integration tests (requires Hyper-V host)
ansible-test integration hv_vm --python 3.9
```

### Sanity Tests
```bash
# Run sanity tests
ansible-test sanity --python 3.9
```

## Code Style

### Python
- Follow PEP 8 style guide
- Use meaningful variable and function names
- Add docstrings to functions and classes
- Maximum line length: 160 characters (Ansible standard)

### Documentation
- Use proper reStructuredText formatting
- Include complete parameter descriptions with types and defaults
- Provide at least 3 examples showing common use cases
- Document all return values

## Pull Request Process

1. **Branch naming**: Use descriptive names (e.g., `feature/hv_vm_module`, `fix/memory_leak`)
2. **Commits**: Write clear commit messages following [Ansible commit message guidelines](https://docs.ansible.com/projects/ansible/devel/community/development_process.html#making-your-pr)
3. **Testing**: Ensure all tests pass
4. **Changelog**: Add a changelog fragment in `changelogs/fragments/`
5. **Documentation**: Update relevant documentation
6. **Review**: Address review comments promptly

### Changelog Fragments
Create a file in `changelogs/fragments/` named `<pr_number>-<description>.yml`:

```yaml
---
minor_changes:
  - hv_vm - Added support for generation 2 VMs
bugfixes:
  - hv_vm_state - Fixed issue with VM state detection
```

## Module Development Workflow

1. **Claim a task** from the roadmap by commenting on the Jira issue
2. **Create a branch** from main
3. **Develop the module** following guidelines
4. **Write tests** (unit and integration)
5. **Test thoroughly** on actual Hyper-V infrastructure
6. **Create documentation**
7. **Add changelog fragment**
8. **Submit PR** with reference to Jira task

## Getting Help

- **Ansible Forum**: Post questions with the `hyperv` tag
- **GitHub Issues**: For bugs and feature requests
- **Jira**: For tracking development tasks
- **IRC**: #ansible on Libera.Chat

## Code of Conduct

This project follows the [Ansible Code of Conduct](https://docs.ansible.com/projects/ansible/devel/community/code_of_conduct.html). Please read and follow it in all interactions.

## Resources

- [Ansible module development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/developing_modules_general.html)
- [Ansible collection development guide](https://docs.ansible.com/projects/ansible/devel/dev_guide/developing_collections.html)
- [Hyper-V PowerShell reference](https://docs.microsoft.com/en-us/powershell/module/hyper-v/)
- [Collection roadmap](ROADMAP.md)
- [Module reference](MODULES.md)

## License

By contributing to this project, you agree that your contributions will be licensed under the GNU General Public License v3.0 or later.

---

For more information, refer to the [Ansible community guide](https://docs.ansible.com/projects/ansible/devel/community/index.html).
