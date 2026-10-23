/**
 * SAMPLE catalog for development and demos only.
 *
 * The final MVP category/service list (open decision D-01) and pricing guidance (D-02) are not
 * approved yet. Every row is flagged `isSample: true`, and every service uses
 * `inspection_required` pricing: no indicative EGP amounts are invented here. Operations will
 * replace this data once the catalog and prices are approved.
 */
import { PricingType } from '../../catalog/catalog.entities';

export interface SampleService {
  slug: string;
  nameAr: string;
  nameEn: string;
  descriptionAr: string;
  descriptionEn: string;
}

export interface SampleCategory {
  slug: string;
  nameAr: string;
  nameEn: string;
  descriptionAr: string;
  descriptionEn: string;
  iconKey: string;
  services: SampleService[];
}

export const SAMPLE_PRICING = { pricingType: PricingType.InspectionRequired } as const;

export const SAMPLE_CATALOG: SampleCategory[] = [
  {
    slug: 'plumbing',
    nameAr: 'سباكة',
    nameEn: 'Plumbing',
    descriptionAr: 'إصلاح التسريبات والحنفيات والسخانات وشبكات المياه.',
    descriptionEn: 'Leaks, taps, water heaters and water lines.',
    iconKey: 'plumbing',
    services: [
      {
        slug: 'plumbing-leak-repair',
        nameAr: 'إصلاح تسريب مياه',
        nameEn: 'Water leak repair',
        descriptionAr: 'كشف وإصلاح تسريبات المواسير والوصلات.',
        descriptionEn: 'Find and fix leaking pipes and joints.',
      },
      {
        slug: 'plumbing-tap-replacement',
        nameAr: 'تركيب أو تغيير حنفية',
        nameEn: 'Tap installation or replacement',
        descriptionAr: 'تركيب حنفيات المطبخ والحمام أو استبدالها.',
        descriptionEn: 'Install or replace kitchen and bathroom taps.',
      },
      {
        slug: 'plumbing-water-heater',
        nameAr: 'صيانة سخان مياه',
        nameEn: 'Water heater service',
        descriptionAr: 'فحص وصيانة سخانات المياه الكهربائية والغاز.',
        descriptionEn: 'Inspect and service electric and gas water heaters.',
      },
    ],
  },
  {
    slug: 'electrical',
    nameAr: 'كهرباء',
    nameEn: 'Electrical',
    descriptionAr: 'الأعطال الكهربائية والإنارة والمفاتيح والبرايز.',
    descriptionEn: 'Electrical faults, lighting, switches and sockets.',
    iconKey: 'electrical',
    services: [
      {
        slug: 'electrical-fault-diagnosis',
        nameAr: 'كشف عطل كهربائي',
        nameEn: 'Electrical fault diagnosis',
        descriptionAr: 'تحديد سبب انقطاع الكهرباء أو فصل القاطع وإصلاحه.',
        descriptionEn: 'Find and fix the cause of power cuts or tripping breakers.',
      },
      {
        slug: 'electrical-lighting-install',
        nameAr: 'تركيب إنارة',
        nameEn: 'Lighting installation',
        descriptionAr: 'تركيب النجف والكشافات ووحدات الإضاءة.',
        descriptionEn: 'Install ceiling lights, spotlights and fixtures.',
      },
    ],
  },
  {
    slug: 'air-conditioning',
    nameAr: 'تكييف',
    nameEn: 'Air conditioning',
    descriptionAr: 'صيانة وتنظيف وشحن أجهزة التكييف.',
    descriptionEn: 'AC servicing, cleaning and refrigerant recharge.',
    iconKey: 'air_conditioning',
    services: [
      {
        slug: 'ac-cleaning',
        nameAr: 'تنظيف وصيانة تكييف',
        nameEn: 'AC cleaning and service',
        descriptionAr: 'تنظيف الفلاتر والوحدات الداخلية والخارجية وفحص الأداء.',
        descriptionEn: 'Clean filters and indoor/outdoor units and check performance.',
      },
      {
        slug: 'ac-not-cooling',
        nameAr: 'تكييف لا يبرّد',
        nameEn: 'AC not cooling',
        descriptionAr: 'فحص أسباب ضعف التبريد وإصلاحها.',
        descriptionEn: 'Diagnose and fix weak or no cooling.',
      },
    ],
  },
  {
    slug: 'carpentry',
    nameAr: 'نجارة',
    nameEn: 'Carpentry',
    descriptionAr: 'إصلاح الأبواب والأثاث والأقفال والدواليب.',
    descriptionEn: 'Doors, furniture, locks and cabinets.',
    iconKey: 'carpentry',
    services: [
      {
        slug: 'carpentry-door-repair',
        nameAr: 'إصلاح باب',
        nameEn: 'Door repair',
        descriptionAr: 'ضبط الأبواب وتغيير المفصلات والأكر.',
        descriptionEn: 'Adjust doors and replace hinges and handles.',
      },
    ],
  },
  {
    slug: 'painting',
    nameAr: 'نقاشة ودهانات',
    nameEn: 'Painting',
    descriptionAr: 'دهان الحوائط والأسقف والمعالجة البسيطة للشروخ.',
    descriptionEn: 'Wall and ceiling painting and minor crack repair.',
    iconKey: 'painting',
    services: [
      {
        slug: 'painting-room',
        nameAr: 'دهان غرفة',
        nameEn: 'Room painting',
        descriptionAr: 'تجهيز ودهان حوائط وسقف غرفة.',
        descriptionEn: 'Prepare and paint the walls and ceiling of a room.',
      },
    ],
  },
  {
    slug: 'appliances',
    nameAr: 'أجهزة منزلية',
    nameEn: 'Home appliances',
    descriptionAr: 'صيانة الغسالات والثلاجات والأجهزة المنزلية.',
    descriptionEn: 'Washing machines, fridges and other appliances.',
    iconKey: 'appliances',
    services: [
      {
        slug: 'appliance-washing-machine',
        nameAr: 'صيانة غسالة',
        nameEn: 'Washing machine repair',
        descriptionAr: 'فحص وإصلاح أعطال الغسالات الأوتوماتيك والعادية.',
        descriptionEn: 'Diagnose and repair automatic and twin-tub washers.',
      },
      {
        slug: 'appliance-refrigerator',
        nameAr: 'صيانة ثلاجة',
        nameEn: 'Refrigerator repair',
        descriptionAr: 'فحص ضعف التبريد والتسريب والأصوات المزعجة.',
        descriptionEn: 'Weak cooling, leaks and noisy operation.',
      },
    ],
  },
];
