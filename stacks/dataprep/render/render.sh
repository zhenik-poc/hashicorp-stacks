sudo consul-template -consul-addr=http://172.17.0.1:8500 -once -template ./test0.ctpl:out.txt