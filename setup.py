import os
from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

# Read version from VERSION file
with open("VERSION", "r", encoding="utf-8") as f:
    version = f.read().strip()

install_requires = [
    'matplotlib',
    'numpy',
    'pyserial',
]

# When building with conda-build, dependency resolution must be handled by
# meta.yaml; avoid setuptools/easy_install trying to fetch from PyPI.
if os.environ.get("CONDA_BUILD"):
    install_requires = []

setup(
    name='alpaca_kernel_2',
    version=version,
    author='Thijn Hoekstra; Krzysztof Zablocki',
    author_email='kzablocki@tudelft.nl',
    description='Fork of jupyter_micropython_kernel and IPythonkernel',
    long_description=long_description,
    long_description_content_type="text/markdown",
    url='https://github.com/NB-TUDelft/alpaca_kernel_2',
    project_urls = {
        "Bug Tracker": "https://github.com/NB-TUDelft/alpaca_kernel_2"
    },
    license='MIT',
    packages=find_packages(),
    package_data={'': ['resources/*', 'resources/*.png']},
    install_requires=install_requires,
)