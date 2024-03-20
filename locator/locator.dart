final GetIt getIt = GetIt.instance;

const fakeEnvironment = Environment('fake');
const httpEnvironment = Environment('http');

@InjectableInit(bool useFakeImplementation)
Future<void> setupLocator() async {
  final Set<String> environments = {};
  environments.add(useFakeImplementation ? fakeEnvironment.name : httpEnvironment.name);

  final EnvironmentFilter envFilter = SimpleEnvironmentFilter(
    filter: (Set<String> env) {
      if (env.isEmpty) return true;

      if (env.contains(fakeEnvironment.name) || env.contains(httpEnvironment.name)) {
        return useFakeImplementation
            ? env.contains(fakeEnvironment.name)
            : env.contains(httpEnvironment.name);
      }

      return false;
    },
    environments: environments,
  );

  await getIt.init(environmentFilter: envFilter);
}
