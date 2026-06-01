import { Container, getContainer } from "@cloudflare/containers";

export class AppContainer extends Container {
  defaultPort = 8080;
  sleepAfter = "10m";
}

export default {
  async fetch(request, env) {
    const container = getContainer(env.APP_CONTAINER, "main");

    await container.startAndWaitForPorts({
      ports: [8080],
      startOptions: {
        envVars: {
          GCP_HOST: env.GCP_HOST
        }
      }
    });

    return container.fetch(request);
  }
};
