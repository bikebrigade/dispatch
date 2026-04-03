// tests/helpers/sandbox.js
import { request, test as base } from '@playwright/test';

async function setupSandbox(context: any) {
  // Create sandbox
  const requestContext = await request.newContext();
  const response = await requestContext.post('http://localhost:4000/sandbox', {
    headers: {
      'Cache-Control': 'no-store'
    }
  });
  
  const sessionId = await response.text();
  
  // Set up the route interception to add sessionId to all requests
  await context.route('**/*', async (route: any, request: any) => {
    const headers = request.headers();
    headers['x-session-id'] = sessionId;
    await route.continue({ headers });
  });
  
  // Store the sessionId for LiveView connections
  await context.addInitScript(({ sessionId }) => {
    window.sessionId = sessionId;
  }, { sessionId });
  
  return sessionId;
}

async function teardownSandbox(sessionId: any) {
  const requestContext = await request.newContext();
  await requestContext.delete('http://localhost:4000/sandbox', {
    headers: {
      'x-session-id': sessionId
    }
  });
}

// module.exports = { setupSandbox, teardownSandbox };



const test =  base.extend({
  context: async ({ context }, use) => {
    const sessionId = await setupSandbox(context);
    console.log("sessionId is >>>>>>>>>>: ", sessionId)
    await use(context);
    await teardownSandbox(sessionId);
  }
});

const expect = base.expect

export {
  test,
  expect
}
