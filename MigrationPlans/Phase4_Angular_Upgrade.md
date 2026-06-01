# Phase 4: Gradual Frontend Upgrade (Angular 7 to Angular 18/19)

This phase establishes the step-by-step roadmap for updating the extracted Angular 7 frontend to the latest stable version of Angular 18/19.

---

## 1. Upgrades Roadmap Overview

Because of breaking changes in the compiler (View Engine -> Ivy), TypeScript, RxJS, and the CLI workspace schemas, we will execute the upgrade in distinct major versions using the Angular CLI command `ng update`.

```text
Angular 7 -> Angular 9 (Ivy Compiler) -> Angular 12 (View Engine Removed) -> Angular 15 (Standalone) -> Angular 18/19 (Signals & LTS)
```

---

## 2. Upgrade Steps

### Giai đoạn A: Nâng cấp lên Angular 9 (Kích hoạt Ivy)
- Objective: Migrate from View Engine to the modern Ivy compilation engine.
- Steps:
  ```bash
  # Upgrade Angular CLI and Core to v8 first
  npx @angular/cli@8 update @angular/core@8 @angular/cli@8
  
  # Upgrade to v9
  npx @angular/cli@9 update @angular/core@9 @angular/cli@9
  ```
- Major Fixes: Resolve TypeScript strict checks and import paths. Verify `tsconfig.json` update.

### Giai đoạn B: Nâng cấp lên Angular 12
- Objective: Remove legacy compilation engines and resolve RxJS updates.
- Steps:
  ```bash
  # Upgrade to v10
  npx @angular/cli@10 update @angular/core@10 @angular/cli@10
  
  # Upgrade to v11
  npx @angular/cli@11 update @angular/core@11 @angular/cli@11
  
  # Upgrade to v12
  npx @angular/cli@12 update @angular/core@12 @angular/cli@12
  ```
- Major Fixes: Replace deprecated RxJS operators (e.g. `flatMap` -> `mergeMap`, check Observable subscriptions).

### Giai đoạn C: Nâng cấp lên Angular 15 (Standalone Components)
- Objective: Switch to clean standalone components and migrate compiler warnings.
- Steps:
  ```bash
  # Upgrade to v13
  npx @angular/cli@13 update @angular/core@13 @angular/cli@13
  
  # Upgrade to v14
  npx @angular/cli@14 update @angular/core@14 @angular/cli@14
  
  # Upgrade to v15
  npx @angular/cli@15 update @angular/core@15 @angular/cli@15
  ```
- Major Fixes: Convert component definitions to Standalone:
  ```typescript
  @Component({
      selector: 'app-login',
      templateUrl: './login.component.html',
      standalone: true,
      imports: [CommonModule, TranslateModule]
  })
  ```
- Replace TSLint with ESLint:
  ```bash
  ng add @angular-eslint/schematics
  ```

### Giai đoạn D: Nâng cấp lên Angular 18/19 (Latest Stable)
- Objective: Upgrade to the latest LTS version, integrating Signals and modern reactive architecture.
- Steps:
  ```bash
  # Upgrade to v16
  npx @angular/cli@16 update @angular/core@16 @angular/cli@16
  
  # Upgrade to v17
  npx @angular/cli@17 update @angular/core@17 @angular/cli@17
  
  # Upgrade to v18/19
  npx @angular/cli@18 update @angular/core@18 @angular/cli@18
  ```
- Major Fixes:
  - Migrate state management to **Angular Signals** for lightning-fast UI updates.
  - Implement **Deferrable Views** (`@defer`) in templates to lazy-load resource-heavy components (like charts, ag-grid, or DICOM imaging modules).

---

## 3. Resolving Third-Party Package Conflicts

Legacy libraries declared in the old `package.json` must be systematically replaced or upgraded to versions compatible with Angular 18/19:

1. **ag-grid-angular**: Upgrade from v20.0.0 to modern versions compatible with Angular 18/19. Update grid configurations and API selectors.
2. **moment**: Migrate from `moment` to a lighter, modern alternative like `date-fns` or `dayjs` if desired, or keep moment.js but ensure proper compilation imports.
3. **cornerstone-core** (DICOM Imaging): Upgrade to modern dicom-parser versions and test ES module packaging compatibility.
4. **bootstrap**: Move from bootstrap v4.3.1 to bootstrap v5+ for clean styling without jQuery dependencies.
