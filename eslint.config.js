const js = require("@eslint/js");

module.exports = [
  {
    ignores: [
      "node_modules/**"
    ]
  },
  js.configs.recommended,
  {
    files: [
      "assets/**/*.js",
      "functions/**/*.js",
      "scripts/**/*.js"
    ],
    languageOptions: {
      ecmaVersion: 2022,
      sourceType: "commonjs",
      globals: {
        __dirname: "readonly",
        console: "readonly",
        exports: "readonly",
        global: "readonly",
        module: "readonly",
        process: "readonly",
        require: "readonly",
        Runtime: "readonly",
        Twilio: "readonly"
      }
    },
    rules: {
      "no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^(context|event)$"
        }
      ]
    }
  }
];
