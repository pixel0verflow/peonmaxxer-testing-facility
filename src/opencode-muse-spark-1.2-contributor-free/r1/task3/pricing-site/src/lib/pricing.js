const RATES = {
  starter: 9,
  team: 18,
  enterprise: 32,
};

const RATES_CENTS = {
  starter: 900,
  team: 1800,
  enterprise: 3200,
};

function roundCentsHalfUp(value) {
  // value is in cents (may be fractional), round half-up to nearest integer cent
  return Math.round(value);
}

export function computePrice({ plan, seats, months, addons = [] }) {
  if (!RATES.hasOwnProperty(plan)) {
    throw new Error(`Invalid plan: ${plan}`);
  }
  if (!Number.isInteger(seats) || seats < 1) {
    throw new Error(`Invalid seats: ${seats}`);
  }
  if (months !== 1 && months !== 12) {
    throw new Error(`Invalid months: ${months}`);
  }
  if (!Array.isArray(addons)) {
    throw new Error(`Invalid addons`);
  }

  const rateCents = RATES_CENTS[plan];

  // seat subtotal in cents with marginal tiers
  // 1-10 full, 11-50 90%, 51+ 75%
  let seatCents = 0;
  const tier1 = Math.min(seats, 10);
  seatCents += tier1 * rateCents;

  if (seats > 10) {
    const tier2 = Math.min(seats - 10, 40);
    // 90% => *9/10
    seatCents += tier2 * rateCents * 0.9;
  }
  if (seats > 50) {
    const tier3 = seats - 50;
    seatCents += tier3 * rateCents * 0.75;
  }
  // Ensure integer cents (floating from *0.9 etc should be integer but round to avoid FP)
  seatCents = Math.round(seatCents);

  // addon sum in cents
  let addonCents = 0;
  for (const addon of addons) {
    if (typeof addon.pricePerMonth !== "number" || isNaN(addon.pricePerMonth) || addon.pricePerMonth < 0) {
      throw new Error(`Invalid addon price`);
    }
    addonCents += Math.round(addon.pricePerMonth * 100);
  }

  const subtotalCents = seatCents + addonCents;

  // undiscounted total: seats * full rate + addons, times months (no volume, no annual)
  const undiscountedSeatCents = seats * rateCents;
  const undiscountedTotalCents = (undiscountedSeatCents + addonCents) * months;

  // monthly raw cents after annual discount
  let monthlyRawCents = subtotalCents;
  if (months === 12) {
    monthlyRawCents = subtotalCents * 0.8;
  }

  const monthlyCents = roundCentsHalfUp(monthlyRawCents);
  const monthly = monthlyCents / 100;

  const totalCents = monthlyCents * months;
  const total = totalCents / 100;

  const savingsCents = undiscountedTotalCents - totalCents;
  // savings rounded to cents (already integer)
  const savings = Math.round(savingsCents) / 100;

  // Ensure two decimal precision via rounding already, but return as numbers
  // To avoid floating artifacts like 21.600000000001, normalize via dividing
  return {
    monthly: Math.round(monthly * 100) / 100,
    total: Math.round(total * 100) / 100,
    savings: Math.round(savings * 100) / 100,
  };
}
