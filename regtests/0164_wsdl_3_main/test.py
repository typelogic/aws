from test_support import *

exec_cmd('ada2wsdl',
         ['-q', '-f', '-I.', '-Pwsdl_3_main',
          '-a', 'http://localhost:7703', 'wsdl_3.ads', '-o', 'wsdl_3.wsdl'])
exec_cmd('wsdl2aws',
         ['-q', '-f', '-cb', '-types', 'wsdl_3', 'wsdl_3.wsdl'])

build_diff('wsdl_3_main');
