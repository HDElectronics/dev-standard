// dev-standard base profile (GIT-001). https://commitlint.js.org
// Requires: npm install --save-dev @commitlint/cli @commitlint/config-conventional
export default {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "header-max-length": [2, "always", 72],
  },
};
