import { request, test as base } from '@playwright/test';

const BASE_URL = 'http://localhost:4002';

async function setupSandbox(context: any) {
  const requestContext = await request.newContext();
  const response = await requestContext.post(`${BASE_URL}/sandbox`, {
    headers: {
      'Cache-Control': 'no-store'
    }
  });

  const sessionId = await response.text();

  // Add sessionId header to all requests for sandbox isolation
  await context.route('**/*', async (route: any, request: any) => {
    const headers = request.headers();
    headers['x-session-id'] = sessionId;
    await route.continue({ headers });
  });

  // Store sessionId for LiveView WebSocket connections
  await context.addInitScript(({ sessionId }: { sessionId: string }) => {
    (window as any).sessionId = sessionId;
  }, { sessionId });

  return sessionId;
}

async function teardownSandbox(sessionId: string) {
  const requestContext = await request.newContext();
  await requestContext.delete(`${BASE_URL}/sandbox`, {
    headers: {
      'x-session-id': sessionId
    }
  });
}

const test = base.extend({
  context: async ({ context }, use) => {
    const sessionId = await setupSandbox(context);
    await use(context);
    await teardownSandbox(sessionId);
  }
});

const expect = base.expect;

export { test, expect };
