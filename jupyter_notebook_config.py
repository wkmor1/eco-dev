# Copyright (c) Jupyter Development Team.
from jupyter_core.paths import jupyter_data_dir
import subprocess
import os
import errno
import stat

USER = os.environ['USER']

c = get_config()
c.NotebookApp.ip = '*'
c.NotebookApp.allow_origin = '*'
c.NotebookApp.port = 8888
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '/home/'+USER
c.NotebookApp.base_url = USER+'-jupyter'
c.NotebookApp.tornado_settings = { 'static_url_prefix': '/'+USER+'-jupyter/static/' }
c.NotebookApp.trust_xheaders = True
c.NotebookApp.server_extensions.append('ipyparallel.nbextension')
	
from IPython.lib import passwd
c.NotebookApp.password = passwd(os.environ['PASSWORD'])
