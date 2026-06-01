import { Container } from "@cloudflare/containers";

export class AppContainer extends Container {
  defaultPort = 8080;
  sleepAfter = "10m";
}

export default {
  async fetch(request, env) {
    return env.APP_CONTAINER.getByName("main").fetch(request);
  }
};
