#!/bin/bash

function Codebase::build() {
    Console::verbose "${INFO}Building codebase${NC}"

    Compose::ensureCliRunning

    Compose::exec 'chmod 600 /data/config/Zed/*.key' || true

    local vendorDirExist=$(Compose::exec '[ ! -f /data/vendor/bin/install ] && echo 0 || echo 1 | tail -n 1' | tr -d " \n\r")
    if [ "$1" = "--force" ] || [ "${vendorDirExist}" == "0" ]; then
        Console::verbose "${INFO}Running composer install${NC}"
        # Compose::exec "composer clear-cache"
        Compose::exec "composer install --no-interaction ${SPRYKER_COMPOSER_MODE}"
        Compose::exec "composer dump-autoload ${SPRYKER_COMPOSER_AUTOLOAD}"
    fi

    Compose::exec 'chmod +x vendor/bin/*' || true

    local generatedDir=$(Compose::exec '[ ! -d /data/src/Generated ] && echo 0 || echo 1 | tail -n 1' | tr -d " \n\r")
    if [ "$1" = "--force" ] || [ "${generatedDir}" == "0" ]; then
        Console::verbose "${INFO}Running build${NC}"
        Compose::exec "vendor/bin/install -r ${SPRYKER_PIPELINE} -s build -s build-development"
    fi

    if [ -n "${SPRYKER_SCHEDULER_APP_ENABLED}" ]; then
        Console::verbose "${INFO}Running build worker codebase${NC}"

        local nodeDir=$(Compose::exec '[ ! -d /data/node_modules ] && echo 0 || echo 1 | tail -n 1' | tr -d " \n\r")
        if [ "${nodeDir}" == "0" ]; then
            Compose::exec "echo y | npm install --silent"
        fi

        Compose::exec "vendor/bin/install -r ${SPRYKER_PIPELINE} -s cronicle-development"
    fi
}
