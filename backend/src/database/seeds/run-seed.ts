/** CLI: `npm run seed:catalog` — loads the SAMPLE catalog. Refuses to run in production. */
import 'reflect-metadata';
import dataSource from '../data-source';
import { seedSampleCatalog } from './seed-catalog';

async function main() {
  if (process.env.NODE_ENV === 'production') {
    console.error('Refusing to load sample catalog data in production.');
    process.exit(1);
  }
  await dataSource.initialize();
  try {
    const result = await seedSampleCatalog(dataSource);
    console.log(
      `Sample catalog: ${result.categoriesInserted} categories and ${result.servicesInserted} services inserted.`,
    );
  } finally {
    await dataSource.destroy();
  }
}

main().catch((err) => {
  console.error('Seed failed:', (err as Error).message);
  process.exit(1);
});
