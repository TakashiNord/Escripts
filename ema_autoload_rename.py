#!/usr/bin/env python

#
# Инструкция по установке и конфигурации РСДУ для SLES.doc
# стр 11.
# Следует также проверить, что скрипты автозапуска прописаны на
#     соответствующих уровнях загрузки (рекомендуемые уровни 3 и 5).
# В директориях /etc/init.d/rc3.d и /etc/init.d/rc5.d должны присутствовать
# символические ссылки K01ema_autoload и S99ema_autoload на скрипт /etc/init.d/ema_autoload
#

import glob
import os
import re

def ema_autoload_rename():
    print 'Before'
    for name in glob.glob('/etc/init.d/rc*/*ema*'):
        print name
        #base = os.path.basename(path)
        #dirname = os.path.dirname(path)
        dirname, filename = os.path.split(name)
        #base, ext = os.path.splitext(filename)
        m1 = re.search('K.*ema.*', filename)
        if m1:
            fn2 = os.path.join(dirname, "K01ema_autoload")
            try:
                os.rename(name, fn2)
            except OSError :
                print "Couldn't rename %s to %s" % (name, fn2)
        m2 = re.search('S.*ema.*', filename)
        if m2:
            fn2 = os.path.join(dirname, "S99ema_autoload")
            try:
                os.rename(name, fn2)
            except OSError :
                print "Couldn't rename %s to %s" % (name, fn2)
    print 'After'
    for name in glob.glob('/etc/init.d/rc*/*ema*'):
        print name
    return 0


ema_autoload_rename()
