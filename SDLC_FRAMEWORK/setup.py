from setuptools import setup, find_packages

setup(
    name="ai_amb",
    version="1.0.0",
    description="AI_AGE_SDLC enabled Python project",
    author="test sdlc",
    author_email="david.d.lin@linvest21.com",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    install_requires=[],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
        ]
    },
    python_requires=">=3.8",
)
