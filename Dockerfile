FROM rocker/r-ver:4.2.0

# System dependencies
# - libgdal/geos/proj: sf, tmap, stars, lwgeom, rgdal, raster
# - libudunits2: units
# - libcurl/ssl: httr, curl, cmdstanr
# - libfontconfig/freetype/cairo: gdtools, svglite, ggiraph
# - libnode/v8: V8 (required by juicyjuice -> gt)
# - libglpk: igraph (tmap dep)
# - libglu/mesa: some rgl deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libcairo2-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libtiff-dev \
    libpng-dev \
    libjpeg-dev \
    libglpk-dev \
    libnode-dev \
    cmake \
    make \
    g++ \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Quarto CLI
RUN QUARTO_VERSION=1.7.3 && \
    wget -q "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" && \
    dpkg -i "quarto-${QUARTO_VERSION}-linux-amd64.deb" && \
    rm "quarto-${QUARTO_VERSION}-linux-amd64.deb"

# Install renv at the version used in forest-IPM era
RUN R -e "install.packages('renv', repos = 'https://cloud.r-project.org', version = '0.17.3')"

WORKDIR /project

# Copy lockfile and restore all packages
COPY renv.lock renv.lock

# Restore packages from lockfile
# - use GITHUB_PAT if set (for forestIPM GitHub install)
# - cache renv library in image layer
ARG GITHUB_PAT=""
ENV GITHUB_PAT=${GITHUB_PAT}
ENV RENV_PATHS_LIBRARY=/project/renv/library

RUN R -e " \
  options(repos = c(CRAN = 'https://cran.r-project.org')); \
  renv::restore(lockfile = 'renv.lock', prompt = FALSE) \
"

# Copy project files
COPY . .

# Default: render the Quarto book
CMD ["quarto", "render", "."]
