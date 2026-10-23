/** Unit tests: colocated *.spec.ts files, no database required. */
module.exports = {
  moduleFileExtensions: ['js', 'json', 'ts'],
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  transform: { '^.+\\.ts$': 'ts-jest' },
  collectCoverageFrom: ['**/*.ts', '!**/*.module.ts', '!main.ts', '!database/migrations/**'],
  coverageDirectory: '../coverage',
  testEnvironment: 'node',
};
