from setuptools import setup, find_packages

extensions = []

reqs = ['ijson', 'requests']

setup(
    name="hiresprv",
    version="1.1.0",
    author="Mihseh Kong, John Good, BJ Fulton",
    classifiers=[
        'Intended Audience :: Science/Research',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Topic :: Scientific/Engineering :: Astronomy'],
    packages=find_packages(),
    data_files=[],
    install_requires=reqs,
    python_requires='>= 3.6',
    include_package_data=False
)
