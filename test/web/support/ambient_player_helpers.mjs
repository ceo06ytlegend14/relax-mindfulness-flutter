// Existing mixer/availability tests deliberately minimize the new full player
// before using background controls. Do not force-click through a modal or add
// an app-side auto-dismiss. Dedicated ambient-player tests assert auto-opening.
export async function minimizeAmbientForBackgroundControls(page) {
  if (await page.locator('#ambient-dialog').isVisible()) {
    await page.locator('#ambient-minimize').click();
  }
}
