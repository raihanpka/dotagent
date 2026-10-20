# TODO: add an invoice route to the billing module

## requirements

- R1: GET /v1/invoices/{id} returns the invoice with its line items.
- R2: 404 when the invoice does not exist.
- R3: GET /v1/invoices lists the invoices of an account.

## decisions

- Money format: integer cents, as the rest of billing does (recommended and accepted)
- Auth: reuse the existing account middleware (recommended and accepted)

## PR 1: feat(billing): add the invoice route

branch: feat/billing-invoice-route
needs: none
covers: R1, R2
read: internal/modules/billing/store.go#Store, internal/modules/billing/http/handler.go#RegisterRoutes

- [x] 1.1 (S) `feat(billing): add the invoice query`. Add `GetInvoice` to `queries/invoice.sql`, run `make sqlc`, never edit the generated files. Verify: gofmt -w ., make build, make lint, make test.
- [x] 1.2 (S) `feat(billing): wrap the invoice query in the store`. Add `Store.GetInvoice` in `store.go`. Verify: gofmt -w ., make build, make lint, make test.
- [x] 1.3 (M) `test(billing): cover the invoice route`. Failing tests for 200 and 404 in `http/handler_test.go`. Verify: gofmt -w ., make test.
- [ ] 1.4 (M) `feat(billing): serve the invoice route`. Add `GET /v1/invoices/:id` in `http/handler.go` until the tests pass. Verify: gofmt -w ., make build, make lint, make test.

done:

## PR 2: feat(billing): list invoices for an account

branch: feat/billing-invoice-list
needs: PR 1
covers: R3

- [ ] 2.1 (M) `feat(billing): add the invoice list query and route`. `ListInvoices` in the store and `GET /v1/invoices` in the handler, with a test. Verify: gofmt -w ., make build, make lint, make test.

done:

## fixes

## noticed

- `internal/modules/billing/http/handler.go` is 480 lines, close to the 500 line mark
