import 'package:example/widgets/widgets.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alchemist Example App'),
      ),
      body: SizedBox.expand(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _ExplanationText(),
              ),
              _ExampleSection(
                title: Text('RedButton'),
                child: _Buttons(),
              ),
              _ExampleSection(
                title: Text('ContactListTile'),
                child: _ListTiles(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleSection extends StatelessWidget {
  const _ExampleSection({
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.headlineSmall,
              child: title,
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 128,
              ),
              child: const Divider(height: 16),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _ExampleScenario extends StatelessWidget {
  const _ExampleScenario({
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.titleSmall,
          child: title,
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ExplanationText extends StatelessWidget {
  const _ExplanationText();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '''
This is an example app that showcases the Alchemist golden testing package.

It contains two custom widgets that each have their own golden tests; a RedButton and a ContactListTile. Both have several variations, all of which are shown below.

The primary goal of this app is to show how to use the Alchemist golden testing package to test widgets. Please see Alchemist's README for more information, and visit the test/ directory in this app to see how these widgets are tested.''',
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _ExampleScenario(
          title: const Text('Enabled'),
          child: RedButton(
            onPressed: () {},
            child: const Text('Button'),
          ),
        ),
        const _ExampleScenario(
          title: Text('Disabled'),
          child: RedButton(
            onPressed: null,
            child: Text('Button'),
          ),
        ),
        _ExampleScenario(
          title: const Text('With icon'),
          child: RedButton(
            onPressed: () {},
            icon: const Icon(Icons.add),
            child: const Text('Button'),
          ),
        ),
        const _ExampleScenario(
          title: Text('Disabled with icon'),
          child: RedButton(
            onPressed: null,
            icon: Icon(Icons.add),
            child: Text('Button'),
          ),
        ),
      ],
    );
  }
}

class _ListTiles extends StatelessWidget {
  const _ListTiles();

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      children: [
        _ExampleScenario(
          title: const Text('Enabled (one name)'),
          child: ContactListTile(
            onPressed: () {},
            name: 'Gerard',
            email: 'gerard@example.com',
          ),
        ),
        _ExampleScenario(
          title: const Text('Enabled (two names)'),
          child: ContactListTile(
            onPressed: () {},
            name: 'Caitlin Smith',
            email: 'caitlinsmith@example.com',
          ),
        ),
        const _ExampleScenario(
          title: Text('Disabled'),
          child: ContactListTile(
            onPressed: null,
            name: 'Danielle Smith',
            email: 'daniellesmith@example.com',
          ),
        ),
      ],
    );
  }
}
