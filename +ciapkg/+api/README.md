# CIAtah API

Biafra Ahanonu

All functions in the `ciapkg.api` package are just pass-through functions to the actual underlying functions. This allows users to import all CIAtah functions into their function or script with `import ciapkg.api.*` as opposed to having to do that for each `ciapkg` sub-package.

Else, users can call nearly all CIAtah functions using `ciapkg.api.[Function Name]`, which allows easier namespacing.