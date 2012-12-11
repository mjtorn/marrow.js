glob = require '../../env/node_modules/glob'
qqunit = require '../../env/node_modules/qqunit'

path = require 'path'

tests = glob.sync '*test*coffee'
suite = (path.resolve(test) for test in tests)

qqunit.Runner.run suite

