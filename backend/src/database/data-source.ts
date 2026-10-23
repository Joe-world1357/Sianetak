/** DataSource used by the TypeORM CLI (`npm run migration:*`) and seed scripts. */
import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { loadConfig } from '../config/config.module';
import { typeormOptions } from './typeorm-options';

export default new DataSource(typeormOptions(loadConfig()));
