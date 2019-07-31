# Delphi-Autofixture
Based on ideas from the .NET Autofixture. Requires Delphi Mocks to be installed

uses DUnitX for unit testing.

There are 3 basic things needed for unit tests in delphi.
1. A unit testing framework, like DUnitX
2. A way to mock classes, which can be done with a mocking framework like Delphi Mocks
3. A way to generate test date, whic can be done easily using AutoFixture.

AutoFixture is created to be an easy way to generate test data.

## Features
At a peek AutoFixtures has the following features
<ul>
<li> Creates objects and initialize them with dummy data for test purposes
<li> Can initialize entire object hierarchies
<li> Highly configurable - how much data do you want, and how should it be initialized
<li> Integrates with Delphi mocks, and provides easy creation, setup and injection of mocks
</ul>

## Future
The following features are not ready, but work is in progress
<ul>
<li> build and configure a single class
<li> Handling of multiple mocks of the same type - currently only one mock object of each class can be active.
<li> Easy setup of multiple mock objects at once.
</ul>
