setup() {
  set -eu -o pipefail

  load 'test_helper/bats-support/load'
  load 'test_helper/bats-assert/load'

  export DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )/.."
  export PROJNAME=test-dkan-ddev-addon
  export TESTDIR=~/tmp/$PROJNAME
  mkdir -p $TESTDIR
  export DDEV_NON_INTERACTIVE=true
  ddev delete -Oy ${PROJNAME} || true
  cd "${TESTDIR}"

  ddev config --project-name=${PROJNAME}
  echo "# ddev get ${DIR} with project ${PROJNAME} in ${TESTDIR} ($(pwd))" >&3
  ddev get ${DIR}
  ddev composer create getdkan/recommended-project:@dev --no-interaction -y
  cat .ddev/misc/settings.dkan-snippet.php.txt >> docroot/sites/default/settings.php
  cp .ddev/misc/settings.dkan.php docroot/sites/default/settings.dkan.php
  ddev restart

  ddev drush si -y
  ddev drush pm-enable dkan -y
}

teardown() {
  set -eu -o pipefail
  echo "teardown..."
  cd ${TESTDIR} || ( printf "unable to cd to ${TESTDIR}\n" && exit 1 )
  ddev delete -Oy ${PROJNAME}
  [ "${TESTDIR}" != "" ] && rm -rf ${TESTDIR}
}

@test "install and build the frontend app" {
  set -eu -o pipefail

  ddev dkan-frontend-install
  ddev dkan-frontend-build
  # run the tests, but ignore the pass/fail. We only care if they ran.
  run ddev dkan-frontend-test
  assert_output --partial '(Run Finished)'
}
