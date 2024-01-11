<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [HykuKnapsack](#hykuknapsack)
  - [Introduction](#introduction)
    - [Precedence](#precedence)
  - [Usage](#usage)
    - [Creating Your Knapsack](#creating-your-knapsack)
      - [New Repository](#new-repository)
      - [Fork on Github](#fork-on-github)
    - [Hyku and HykuKnapsack](#hyku-and-hykuknapsack)
    - [Overrides](#overrides)
    - [Deployment scripts](#deployment-scripts)
    - [Theme files](#theme-files)
    - [Gems](#gems)
  - [Converting a Fork of Hyku Prime to a Knapsack](#converting-a-fork-of-hyku-prime-to-a-knapsack)
  - [Installation](#installation)
  - [Contributing](#contributing)
  - [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# HykuKnapsack

[Hyku Knapsack](https://github.com/samvera-labs/hyku_knapsack) is a little wrapper around Hyku to make development and deployment easier. Primary goals of this project
include making contributing back to the Hyku project easier and making upgrades a snap.

## Introduction

[Hyku](https://github.com/samvera/hyku) is a Rails application that leverages Rails Engines and other gems to provide functionality.  A Hyku Knapsack is also a Rails engine, but it integrates differently than other engines.

### Precedence

In a traditional setup, a Rails' application's views, translations, and code supsedes all other gems and engines.  However, we have setup Hyku Knapsack to have a higher load precedence than the underlying Hyku application.

The goal being that a Hyku Knapsack should make it easier to maintain, upgrade, and contribute fixes back to Hyku.

See [Overrides](#overrides) for more discussion on working with a Hyku Knapsack.

## Usage

### Creating Your Knapsack

In working on a Hyku Knapsack, you want to be able to track changes in the upstream knapsack as well as make local changes for your application.  Start by making a clone.  You can do this by:

- _Preferred_ Creating a [New Repository](#new-repository) and pushing your local clone
- Creating a [Fork on Github](#fork-on-github)

#### New Repository

In your Repository host of choice, create a new (and for now empty) repository.

- `$PROJECT_NAME` must only contain letters, numbers and underscores due to a bundler limitation.
- `$NEW_REPO_URL` is the location of your application's knapsack git project (e.g. https://github.com/my-org/my_org_knapsack)

```bash
git clone https://github.com/samvera-labs/hyku_knapsack $PROJECT_NAME_knapsack
cd $PROJECT_NAME_knapsack
git remote rename origin prime
git remote add origin $NEW_REPO_URL
git branch -M main
git push -u origin main
```

Naming the `samvera-labs/hyku_knapsack` as `prime` helps clarify what we mean.  In conversations about Hyku instances, invariably we use the language of Prime to reflect what's in Samvera's repositories.  By using that language for remotes, we help reinforce the concept that `https://github.com/samvera/hyku` is Hyku prime and `https://github.com/samvera-labs/hyku_knapsack` is Knapsack prime.

#### Fork on Github

If you choose to fork Knapsack, be aware that this will impact how you manage pull requests via Github.  Namely as you submit PRs on your Fork, the UI might default to applying that to the fork's origin (e.g. Knapsack upstream).

To ease synchronization of your Knapsack and Knapsack “prime”, consider adding knapsack prime as a remote:

```bash
cd $PROJECT_NAME_knapsack
git remote add prime https://github.com/samvera-labs/hyku_knapsack
```

### Hyku and HykuKnapsack

You run your Hyku application by way of the HykuKnapsack.  As mentioned, the HykuKnapsack contains your application's relevant information for running an instance of Hyku.

There are two things you need to do:

- Ensure you have the [reserved branch](#reserved-branch)
- Initialize the [Hyku submodule](#hyku-submodule)

#### Reserved Branch

Knapsack turns the assumptions of a Rails engine upside-down; the application overlays traditional engines, but Knapsack overlays the application.  As such the Gemfile declared in Hyku does some bundler trickery.

In the `$PROJECT_NAME_knapsack` directory, you need to run the following:

```bash
git fetch prime
git checkout prime/required_for_knapsack_instances
git switch -c required_for_knapsack_instances
```

For Hyku to build with Knapsack, we need a local branch named `required_for_knapsack_instances`.  _Note:_ As we work more with Knapsack maintenance there may be improvements to this shim.

#### Hyku Submodule

A newly cloned knapsack will have an empty `./hyrax-webapp` directory.  That is where the Hyku application will exist.  The version of Hyku is managed via a [Git submodule](https://git-scm.com/docs/git-submodule).

To bring that application into your knapsack, you will need to initialize the Hyku submodule:

```bash
❯ git submodule init
Submodule 'hyrax-webapp' (https://github.com/samvera/hyku.git) registered for path 'hyrax-webapp'
```

Then update the submodule to clone the remote Hyku repository into `./hyrax-webapp`.  The `KNAPSACK-SPECIFIED-HYKU-REPOSITORY-SHA` is managed within the Hyku Knapsack (via Git submodules).

```bash
❯ git submodule update
Cloning into '/path/to/$PROJECT_NAME_knapsack/hyrax-webapp'...
Submodule path 'hyrax-webapp': checked out '<KNAPSACK-SPECIFIED-HYKU-REPOSITORY-SHA>'
```

The configuration of the submodule can be found in the `./.gitmodules` file.  During development, we've specified the submodule's branch (via `git submodule set-branch --branch <NAME> -- ./hyrax-webapp`).

Below is an example of our Adventist Knapsack submodule.

```
❯ cat .gitmodules
[submodule "hyrax-webapp"]
	path = hyrax-webapp
	url = https://github.com/samvera/hyku.git
	branch = adventist_dev
```

When you want to bring down an updated version of your Hyku submodule, use the following:

```bash
> git submodule update --remote
```

This will checkout the submodule to the HEAD of the specified branch.

### Overrides

Before overriding anything, please think hard (or ask the community) about whether what you are working on is a bug or feature that can apply to Hyku itself. If it is, please make a branch in your Hyku checkout (`./hyrax-webapp`) and do the work there. [See here](https://github.com/samvera-labs/hyku_knapsack/wiki/Hyku-Branches) for more information about working with Hyku branches in your Knapsack

Adding decorators to override features is fairly simple. We do recommend some best practices [found here](https://github.com/samvera-labs/hyku_knapsack/wiki/Decorators-and-Overrides)

Any file with `_decorator.rb` in the app or lib directory will automatically be loaded along with any classes in the app directory.

### Deployment scripts

Deployment code can be added as needed.

### Theme files

Theme files (views, css, etc) can be added in the the Knapsack. We recommend adding an override comment as [described here](https://github.com/samvera-labs/hyku_knapsack/wiki/Decorators-and-Overrides)

### Gems

It can be useful to add additional gems to the bundle. This can be done w/o editing Hyku by adding them to the [./bundler.d/example.rb](./bundler.d/example.rb].  [See the bundler-inject documentation for more details] on overriding and adding gems.

## Converting a Fork of Hyku Prime to a Knapsack

Prior to Hyku Knapsack, organizations would likely clone [Hyku](https://github.com/samvera/hyku) and begin changing the code to reflect their specific needs.  The result was that the clone would often drift away from Samvera Hyku version.  This drift created challenges in reconciling what you had changed locally as well as how you could easily contribute some of your changes upstream to Samvera's Hyku.

With Hyku Knapsack, the goal is three-fold:

1. To isolate the upstream Samvera Hyku code from your local modifications.  This isolation is via the `./hyrax-webapp` submodule.
2. To provide a clear and separate space for extending/overriding Hyku functionality.
3. To provide a cleaner pathway for upgrading the underlying Hyku application; for things such as security updates, bug fixes, and upstream enhancements.

From those goals, we can begin to see what we want in our Hyku Knapsack:

1. Files that are not found in Hyku
2. Or files that are different from what is in Hyku (and thus will be loaded at a higher precedence)

Assuming you're working from a fork of Samvera's Hyku repository, these are some general steps.  First clone the Hyku Knapsack ([see the Usage section](#usage)).  You'll also want to initialize the git submodule.  Point the `./hyrax-webapp` to the branch/SHA of Samvera's Hyku that you want to use; **Note:** that version must include a `gem 'hyku_knapsack'` declaration (e.g. introduced in  [7853fe5d](https://github.com/samvera/hyku/blob/7853fe5d79afd9d90cec3b9ef666681b287ef4d0/Gemfile)).

You'll also want to have a local copy of your Hyku application.

You can then use `bin/knapsacker` to generate a list of files that need review.  That will give you a list of:

- Files in your Hyku that are exact duplicates of upstream Hyku file (prefix with `=`)
- Files that are in your Hyku but not in upstream Hyku (prefixed with `+`)
- Files that are changed in your Hyku relative to upstream Hyku (prefix with `Δ`)

You can pipe that output into a file and begin working on reviewing and moving files into the Knapsack.  This is not an easy to automate task, after all we're paying down considerable tech debt.

Once you've moved over the files, you'll want to boot up your Knapsack and then work through your test plan.

The `bin/knapsacker` is general purpose.  I have used it to compare one non-Knapsack Hyku instance against Samvera's Hyku.  I have also used it to compare a Knapsack's file against it's submodule Hyku instance.

## Installation

If not using a current version, add this line to Hyku's Gemfile:

```ruby
gem "hyku_knapsack", github: 'samvera-labs/hyku_knapsack', branch: 'main'
```

And then execute:
```bash
$ bundle
```

## Contributing

Contribution directions go here.

## License

The gem is available as open source under the terms of the [Apache 2.0](https://opensource.org/license/apache-2-0/).
