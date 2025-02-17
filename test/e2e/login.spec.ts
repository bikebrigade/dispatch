import { test, expect, Page } from '@playwright/test';

const programName = `Test Program ${Date.now()}`;

test.describe('Login and Logout', () => {
  test('Can Login', async ({ page }) => {
    await doLogin(page)
    await expect(page.locator('#flash')).toContainText('Success! Welcome!');
  })
  test('Validates phone number', async ({ page }) => {
    await page.goto('http://localhost:4000/login');
    await page.getByRole('textbox', { name: 'Phone Number' }).click();
    await page.getByRole('textbox', { name: 'Phone Number' }).fill('647555');
    await page.getByRole('button', { name: 'Get Login Code' }).click();
    await expect(page.locator('#login-form')).toContainText('phone number is not valid for Canada');
  });

  test('Cancel button returns to login page', async ({ page }) => {
    await page.goto('http://localhost:4000/login');
    await page.getByRole('textbox', { name: 'Phone Number' }).click();
    await page.getByRole('textbox', { name: 'Phone Number' }).fill('6475555555');
    await page.getByRole('button', { name: 'Get Login Code' }).click();
    await page.getByRole('link', { name: 'Cancel' }).click();
    await expect(page.getByRole('button')).toContainText('Get Login Code');
  });

  test('Clicking sign up takes you to marketing site', async ({ page }) => {
    await page.goto('http://localhost:4000/login');
    await page.getByRole('link', { name: 'Sign Up!' }).click();
    await expect(page.locator('h2')).toContainText('Join the Brigade.');
  });
  test('Can Logout', async ({ page }) => {
    await doLogin(page)
    await page.getByRole('link', { name: 'Log out' }).click();
    await expect(page.locator('#flash')).toContainText('Success! Goodbye');
  });
})

test.describe('Programs', () => {

  test('Can create and edit program', async ({ page }) => {
    await doLogin(page) // only needs to run once per describe block
    await page.goto('http://localhost:4000/programs');

    createProgram(page, programName)
    await expect(page.getByRole('link', { name: programName, exact: true })).toBeVisible();

    // editing of program

    await page.getByRole('link', { name: `Edit , ${programName}` }).click();
    await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).click();
    await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).fill('This is a test program that was updated');
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('Success! program updated')).toBeVisible();

    await page.getByRole('link', { name: `Edit , ${programName}` }).click();
    await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).click();
    await expect(page.getByLabel('Campaign Blurb (please keep')).toContainText('This is a test program that was updated');

  })
})

test.describe('Campaigns', () => {
  let page: Page

  test.beforeAll(async ({ browser }) => {
    const programName = `Test Program for New Campaign ${Date.now()}`;
    page = await browser.newPage()
    await doLogin(page)
    await createProgram(page, programName)
  })

  test('Can create a campaign', async () => {
    await page.goto('http://localhost:4000/campaigns/new');
    await page.getByRole('textbox', { name: 'Delivery Date' }).fill(getDatePlusDays(0));
    // TODO: this won't select option by label, meaning it's selecting an arbitrary program.
    await page.locator('#user-form_program_id').selectOption("3"); // << this works but isn't ideal
    await page.locator('#location-form-location-input-open').click();
    await page.locator('[id="campaign_form\\[location\\]_address"]').click();
    await page.locator('[id="campaign_form\\[location\\]_address"]').fill('123 yonge');
    await page.waitForTimeout(2000);
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('Success! Campaign created')).toBeVisible({ timeout: 10000 });
  })

  test('Can create a campaign for next week', async () => {
    await page.goto('http://localhost:4000/campaigns/new');
    await page.getByRole('textbox', { name: 'Delivery Date' }).fill(getDatePlusDays(8));
    // TODO: this won't select option by label, meaning it's selecting an arbitrary program.
    await page.locator('#user-form_program_id').selectOption({label: programName});
    // await page.locator('#user-form_program_id').selectOption("3");
    await page.locator('#location-form-location-input-open').click();
    await page.locator('[id="campaign_form\\[location\\]_address"]').click();
    await page.locator('[id="campaign_form\\[location\\]_address"]').fill('123 yonge');
    await page.waitForTimeout(2000);
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('Success! Campaign created')).toBeVisible({ timeout: 10000 });
    // now go check that campaign shows up next week.
    await page.getByRole('link', { name: 'Campaigns' }).click();
    // goto next week
    await page.getByRole('navigation', { name: 'Pagination' }).getByRole('link').nth(2).click();
    // ensure that new campaign for next-week is present
    await expect(page.locator('#campaign-4')).toContainText('Test Program 1739811044662 edited');
    await expect(page.getByRole('link', { name: 'Test Program 1739811044662' })).toBeVisible();
  })
})

async function doLogin(page: any) {
  await page.goto('http://localhost:4000/login');
  await page.getByRole('textbox', { name: 'Phone Number' }).click();
  await page.getByRole('textbox', { name: 'Phone Number' }).fill('6475555555');
  await page.getByRole('button', { name: 'Get Login Code' }).click();
  await page.getByRole('textbox', { name: 'Authentication Code' }).click();
  await page.getByRole('textbox', { name: 'Authentication Code' }).fill('123456');
  await page.getByRole('button', { name: 'Sign in' }).click();
}


// async function createCampaign(page: any) {
//   await page.getByRole('link', { name: 'Campaigns' }).click();
//   await page.getByRole('link', { name: 'New Campaign' }).click();
//   await page.getByRole('textbox', { name: 'Delivery Date' }).fill(getDatePlusDays(0));
//   await page.locator('#user-form_program_id').selectOption({});
//   await page.locator('#location-form-location-input-open').click();
//   await page.locator('[id="campaign_form\\[location\\]_address"]').click();
//   await page.locator('[id="campaign_form\\[location\\]_address"]').fill('123 yonge');
//   await page.waitForTimeout(2000);
//   await page.getByRole('button', { name: 'Save' }).click();
//   await expect(page.getByText('Success! Campaign created')).toBeVisible({ timeout: 10000 });
// }

// async function createCampaignForNextWeek(page: any) { }


function getDatePlusDays(daysToAdd: number) {
  const today = new Date();
  const futureDate = new Date(today);
  futureDate.setDate(today.getDate() + daysToAdd);

  const year = futureDate.getFullYear();
  const month = String(futureDate.getMonth() + 1).padStart(2, '0');
  const day = String(futureDate.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

async function createProgram(page: Page, programName: string) {
  await page.goto('http://localhost:4000/programs');
  await page.getByRole('link', { name: 'Programs' }).click();
  await page.getByRole('link', { name: 'New Program' }).click();
  await page.getByRole('textbox', { name: 'Name', exact: true }).click();
  await page.getByRole('textbox', { name: 'Name', exact: true }).fill(programName);
  await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).click();
  await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).fill('This is a test program');
  await page.getByRole('textbox', { name: 'About (internal description)' }).click();
  await page.getByRole('textbox', { name: 'About (internal description)' }).fill('This is an internal description');
  await page.getByRole('textbox', { name: 'Start Date' }).fill('2025-02-12');
  await page.getByRole('checkbox', { name: 'Public' }).check();
  await page.getByRole('checkbox', { name: 'Hide Pickup Address' }).check();
  await page.getByRole('button', { name: 'Add Schedule' }).click();
  await page.getByRole('textbox', { name: 'Photo Descriotion' }).click();
  await page.getByRole('textbox', { name: 'Photo Descriotion' }).fill('1 Large Box');
  await page.getByRole('textbox', { name: 'Contact Name' }).click();
  await page.getByRole('textbox', { name: 'Contact Name' }).fill('Joe Cool');
  await page.getByRole('textbox', { name: 'Contact Name' }).press('Tab');
  await page.getByRole('textbox', { name: 'Contact Email' }).fill('joecool@gmail.com');
  await page.getByRole('textbox', { name: 'Contact Email' }).press('Tab');
  await page.getByRole('textbox', { name: 'Contact Phone' }).fill('6475555554');
  await page.getByRole('button', { name: 'Save' }).click();
}
