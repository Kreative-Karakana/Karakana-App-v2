# Karakana V2 Documentation Checklist

> Reader note: This checklist is the V2 mobile documentation quality gate. Use it during feature work so documentation does not become a separate cleanup project later.

Use this checklist when adding or changing a mobile feature.

## Screen and Flow Coverage

- [ ] Entry points and route names are documented.
- [ ] Normal user and trainer behavior are documented separately where roles differ.
- [ ] Loading, empty, error, retry, and success states are documented.
- [ ] API endpoints and required fields are listed.
- [ ] Secure storage/session impact is documented.
- [ ] Push notification/device token behavior is documented when affected.
- [ ] Android/iOS differences are documented.
- [ ] Screenshots or design references are attached where helpful.

## Technical Coverage

- [ ] Provider/service/model files are listed.
- [ ] Backend dependencies are linked to backend docs or issue numbers.
- [ ] Validation and formatting rules are documented.
- [ ] Offline/network behavior is documented.
- [ ] Test strategy is documented or marked as a gap.

## Release Coverage

- [ ] Version/build impact is documented.
- [ ] Store-release impact is documented.
- [ ] Migration or compatibility notes are documented.
- [ ] Known limitations and future improvements are listed.

## Quality Bar

- [ ] Docs reflect Karakana V2 code, not V1 assumptions.
- [ ] Swahili user-facing labels are accurate.
- [ ] Technical prose is in English.
- [ ] No secrets or private credentials are included.
