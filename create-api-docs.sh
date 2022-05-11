#!/bin/bash

_date=$(date +%Y-%m-%d)

create_integration_docs() {
    echo "\
---
title: TSD API integration
output:
    html_document:
        toc: true
        toc_float: true
    pdf_document:
        toc: true
        toc_depth: 2
---

Generated on: $_date" >> tsd-api-integration.Rmd

    cat ./integration/proxy-api.md \
        ./integration/auth-api.md \
        ./integration/tsd-oidc.md \
        ./integration/file-api.md \
        ./integration/consent.md \
        ./integration/apps-api.md \
        ./integration/survey-api.md \
        ./integration/publication-api.md >> tsd-api-integration.Rmd

    R -q -e "library(rmarkdown); render('tsd-api-integration.Rmd', output_format='html_document')"
    R -q -e "library(rmarkdown); render('tsd-api-integration.Rmd', output_format='pdf_document')"
    rm ./tsd-api-integration.Rmd
}

create_integration_docs
