# consult-ag.el

[![MELPA](https://melpa.org/packages/consult-ag-badge.svg)](https://melpa.org/#/consult-ag)
[![MELPA Stable](https://stable.melpa.org/packages/consult-ag-badge.svg)](https://stable.melpa.org/#/consult-ag)

[The Silver Searcher](https://github.com/ggreer/the_silver_searcher) integration for GNU Emacs using [Consult](https://github.com/minad/consult).

## Requirements

* GNU Emacs >= 27.1
* Consult >= 0.32
* The Silver Searcher

## Usage

### `consult-ag`

Search with `ag`. By default it search for project directory (found by `consult-project-function`),
otherwise the `default-directory` will be searched.

## Alternatives

* [ag.el](https://github.com/Wilfred/ag.el)
* [helm-ag.el](https://github.com/emacsorphanage/helm-ag) is another `ag` interface with [helm](https://github.com/emacs-helm/helm)
