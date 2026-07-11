# Karakana V2 Mobile Documentation

> Reader note: This is the entry point for Karakana V2 documentation. It explains where each source document lives and prevents V2 docs from being confused with the old V1 app docs.

## Purpose

This documentation is the baseline for the Karakana V2 Flutter app. It documents the current V2 implementation from code, not the old V1 app.

Use old docs under `old-dev/Karakana-App/docs/` only as reference material after verifying that the same behavior exists in V2.

## Documentation Map

- `architecture.md` documents project structure, routing, providers, API integration, secure storage, and UI conventions.
- `setup.md` documents local setup, environment configuration, platform prerequisites, and validation commands.
- `flows.md` documents the current user, trainer, payment, notification, profile, support, course, and eBook flows.
- `ci-cd.md` documents Flutter CI gates, protected release workflows, required secrets, and build environment expectations.
- `release.md` documents Android and iOS release preparation.
- `documentation-checklist.md` defines the documentation quality bar for future V2 changes.
- Existing release/audit notes remain available in this directory for historical context.

## Current V2 Scope

The app currently includes:

- Splash, onboarding, email/password auth, Google auth, Apple auth, biometric login, email verification, and forgot-password flows.
- Normal-user home, course browsing/search, course detail, classroom, video lesson, reviews, completion, wishlist, and my-courses flows.
- eBook store, eBook detail, eBook library, and secure reader flows.
- Trainer dashboard, account, course builder, lesson manager, quiz manager, student progress, and trainer eBook management flows.
- Payments, wallet, user transactions, and payment-success flows.
- Notifications, support tickets, profile editing, password change, terms, account deletion, and trainer application flows.
- Zana tools including business management, eBooks, insurance, POS, and Kikoba entry points.

## Documentation Standard

- Technical documentation is written in English.
- Swahili is reserved for user-facing app content.
- Docs should explain real V2 behavior and list backend dependencies clearly.
- Screenshots and diagrams should be added for major flows as they stabilize.
- Any missing backend/API field should be documented instead of hidden behind frontend assumptions.
