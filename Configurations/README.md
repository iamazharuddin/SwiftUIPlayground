# `Configurations/`

Build settings as version-controlled `.xcconfig` text — one file per environment. Environments
(Dev / QA / Staging / Production) differ only by values like `API_BASE_URL`, `BUNDLE_ID_SUFFIX`,
`PRODUCT_NAME`, and feature flags. Schemes point at the matching `.xcconfig`. Full treatment in
[docs/cicd/part-19](../docs/cicd/part-19-environments.md) (forthcoming).

Planned files: `Base.xcconfig`, `Dev.xcconfig`, `QA.xcconfig`, `Staging.xcconfig`,
`Production.xcconfig`.

> Empty for now — real content arrives in Batch 7 (Part 19).
