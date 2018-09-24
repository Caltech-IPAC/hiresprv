from setuptools import setup, find_packages

extensions = []

reqs = ['ijson', 'requests']

setup(
    name="hiresprv",
    version="1.0.0",
    author="Mihseh Kong, John Good, BJ Fulton",
    packages=find_packages(),
    data_files=[],
    install_requires=reqs,
    include_package_data=False
)
