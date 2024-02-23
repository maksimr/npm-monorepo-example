import { server } from "./server";

const port = process.env.APP_PORT ?? 3000;

server.listen(port, () => {
  console.log('server is listening on ' + port);
});
