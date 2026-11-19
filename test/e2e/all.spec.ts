import { Page } from '@playwright/test';
import { test, expect } from "./helpers/sandbox";
import { faker } from '@faker-js/faker';

test.describe('Login and Logout', () => {
  test('Can Login', async ({ page }) => {
    await doLogin(page);
    await expect(page.locator('#flash')).toContainText('Success! Welcome!');
  });

  test('Validates phone number', async ({ page }) => {
    await page.goto('/login');
    await page.getByRole('textbox', { name: 'Phone Number' }).fill('647555');
    await page.getByRole('button', { name: 'Get Login Code' }).click();
    await expect(page.locator('#login-form')).toContainText('phone number is not valid for Canada');
  });

  test('Cancel button returns to login page', async ({ page }) => {
    await page.goto('/login');
    await page.getByRole('textbox', { name: 'Phone Number' }).fill('6475555555');
    await page.getByRole('button', { name: 'Get Login Code' }).click();
    await page.getByRole('link', { name: 'Cancel' }).click();
    await expect(page.getByRole('button')).toContainText('Get Login Code');
  });

  test('Can Logout', async ({ page }) => {
    await doLogin(page);
    await page.getByRole('link', { name: 'Log out' }).click();
    await expect(page.locator('#flash')).toContainText('Success! Goodbye');
  });
});

test.describe('Programs', () => {
  test('Can create and edit program', async ({ page }) => {
    const programName = faker.company.name();
    await doLogin(page);

    await createProgram(page, programName);
    await expect(page.getByRole('link', { name: programName, exact: true })).toBeVisible();

    // Edit the program
    await page.getByRole('link', { name: `Edit , ${programName}` }).click();
    await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).fill('This is a test program that was updated');
    await page.getByRole('button', { name: 'Save' }).click();
    await expect(page.getByText('Success! program updated')).toBeVisible();

    // Verify the edit persisted
    await page.getByRole('link', { name: `Edit , ${programName}` }).click();
    await expect(page.getByLabel('Campaign Blurb (please keep')).toContainText('This is a test program that was updated');
  });
});

test.describe('Campaigns', () => {
  test('Can create a campaign for today', async ({ page }) => {
    const programName = faker.company.name();
    await doLogin(page);
    await createProgram(page, programName);

    await createCampaign({ page, programName, numDays: 0 });
    await expect(page.locator('#flash')).toContainText('Success! Campaign created successfully');
    await expect(page.getByText(programName)).toBeVisible();
  });

  test('Can create a campaign for next week', async ({ page }) => {
    const programName = faker.company.name();
    await doLogin(page);
    await createProgram(page, programName);

    await createCampaign({ page, programName, numDays: 8 });
    await expect(page.locator('#flash')).toContainText('Success! Campaign created successfully');

    // Verify campaign shows up on next week's view
    await page.getByRole('link', { name: 'Campaigns' }).click();
    await page.getByRole('navigation', { name: 'Pagination' }).getByRole('link').nth(2).click();
    await expect(page.getByText(programName)).toBeVisible();
  });
});

test.describe('Riders', () => {
  test('Can view the riders list', async ({ page }) => {
    await doLogin(page);
    await page.goto('/riders');
    await expect(page.getByRole('heading', { name: 'Riders' })).toBeVisible();
  });

  test('Can search for a rider by name', async ({ page }) => {
    await doLogin(page);
    await page.goto('/riders');
    const searchBox = page.getByRole('textbox', { name: /search/i });
    await searchBox.fill('Dispatcher');
    await expect(page.getByText('Dispatcher')).toBeVisible();
  });
});

test.describe('Navigation', () => {
  test('Sidebar navigation links work', async ({ page }) => {
    await doLogin(page);

    // Navigate to Campaigns
    await page.getByRole('link', { name: 'Campaigns' }).click();
    await expect(page).toHaveURL(/\/campaigns/);

    // Navigate to Programs
    await page.getByRole('link', { name: 'Programs' }).click();
    await expect(page).toHaveURL(/\/programs/);

    // Navigate to Riders
    await page.getByRole('link', { name: 'Riders' }).click();
    await expect(page).toHaveURL(/\/riders/);
  });

  test('Unauthenticated user is redirected to login', async ({ page }) => {
    await page.goto('/campaigns');
    await expect(page).toHaveURL(/\/login/);
  });
});

// --- Helper functions ---

async function doLogin(page: Page) {
  await page.goto('/login');
  await page.getByRole('textbox', { name: 'Phone Number' }).fill('6475555555');
  await page.getByRole('button', { name: 'Get Login Code' }).click();
  await page.getByRole('textbox', { name: 'Authentication Code' }).fill('123456');
  await page.getByRole('button', { name: 'Sign in' }).click();
}

function getDatePlusDays(daysToAdd: number): string {
  const today = new Date();
  const futureDate = new Date(today);
  futureDate.setDate(today.getDate() + daysToAdd);

  const year = futureDate.getFullYear();
  const month = String(futureDate.getMonth() + 1).padStart(2, '0');
  const day = String(futureDate.getDate()).padStart(2, '0');

  return `${year}-${month}-${day}`;
}

async function createProgram(page: Page, programName: string) {
  await page.goto('/programs');
  await page.getByRole('link', { name: 'New Program' }).click();
  await page.getByRole('textbox', { name: 'Name', exact: true }).fill(programName);
  await page.getByRole('textbox', { name: 'Campaign Blurb (please keep' }).fill('This is a test program');
  await page.getByRole('textbox', { name: 'About (internal description)' }).fill('This is an internal description');
  await page.getByRole('textbox', { name: 'Start Date' }).fill('2025-02-12');
  await page.getByRole('checkbox', { name: 'Public' }).check();
  await page.getByRole('checkbox', { name: 'Hide Pickup Address' }).check();
  await page.getByRole('button', { name: 'Add Schedule' }).click();

  await page.getByRole('textbox', { name: 'Photo Description' }).fill('1 Large Box');
  await page.getByRole('textbox', { name: 'Contact Name' }).fill('Joe Cool');
  await page.getByRole('textbox', { name: 'Contact Email' }).fill('joecool@gmail.com');
  await page.getByRole('textbox', { name: 'Contact Phone' }).fill('6475555554');
  await page.getByRole('button', { name: 'Save' }).click();

  // Edit the program to add items (can't add items during creation)
  await page.getByRole('link', { name: programName, exact: true }).click();
  await page.getByRole('link', { name: 'Edit', exact: true }).click();
  await page.getByRole('link', { name: 'New Item' }).click();
  await page.locator('#program-form_program_0_items_0_name').fill('An item');
  await page.locator('#program-form_program_0_items_0_description').fill('5 lbs');
  await page.getByRole('cell', { name: 'Foodshare Box' }).getByLabel('').selectOption('Food Hamper');
  await page.getByRole('button', { name: 'Save' }).click();
}

async function createCampaign({ page, programName, numDays }: { page: Page; programName: string; numDays: number }) {
  await page.goto('/campaigns/new');
  await page.waitForSelector("body > .phx-connected");
  await page.getByRole('textbox', { name: 'Delivery Date' }).fill(getDatePlusDays(numDays));

  const programSelector = page.locator('#user-form_program_id');
  await programSelector.selectOption({ label: programName });

  await page.locator('#location-form-location-input-open').click();
  await page.locator('#location-form-location-input-open').pressSequentially("200 Yonge", { delay: 200 });
  await page.getByRole('button', { name: 'Save' }).click();
}
