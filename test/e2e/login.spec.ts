import { test, expect } from '@playwright/test';


async function doLogin(page: any) {
  await page.goto('http://localhost:4000/login');
  await page.getByRole('textbox', { name: 'Phone Number' }).click();
  await page.getByRole('textbox', { name: 'Phone Number' }).fill('6475555555');
  await page.getByRole('button', { name: 'Get Login Code' }).click();
  await page.getByRole('textbox', { name: 'Authentication Code' }).click();
  await page.getByRole('textbox', { name: 'Authentication Code' }).fill('123456');
  await page.getByRole('button', { name: 'Sign in' }).click();
}

test('standard flow', async ({ page }) => {
  await doLogin(page)
  await createProgram(page);
  await editProgram(page)
  await createCampaign(page);

});

// requires login
async function createProgram(page: any) {
  await page.goto('http://localhost:4000/programs');

  const browserName = page.context().browser()?.browserType().name();
  const programName = `Program ${Date.now()}`;

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
  await expect(page.getByRole('link', { name: programName, exact: true })).toBeVisible();
}

async function editProgram(page: any) {
  await page.goto('http://localhost:4000/programs');
  await page.getByRole('link', { name: 'Edit , Program' }).click();
  await page.getByRole('textbox', { name: 'Name', exact: true }).click();
  await page.getByRole('textbox', { name: 'Name', exact: true }).fill('Program Updated');
  await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).click();
  await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).fill('This is a test program that was updated');
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByRole('link', { name: 'Program Updated', exact: true })).toBeVisible();
  await expect(page.getByText('Success! program updated')).toBeVisible();
}

async function createCampaign(page: any) {
  await page.getByRole('link', { name: 'Campaigns' }).click();
  await page.getByRole('link', { name: 'New Campaign' }).click();
  // TODO: change date for campaign to take param from function
  await page.getByRole('textbox', { name: 'Delivery Date' }).fill('2025-02-20');
  await page.locator('#user-form_program_id').selectOption('3');
  await page.locator('#location-form-location-input-open').click();
  await page.locator('[id="campaign_form\\[location\\]_address"]').click();
  await page.locator('[id="campaign_form\\[location\\]_address"]').fill('123 yonge');
  await page.waitForTimeout(2000);
  await page.getByRole('button', { name: 'Save' }).click();
  await expect(page.getByText('Success! Campaign created')).toBeVisible({timeout: 10000});
}
