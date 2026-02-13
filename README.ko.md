# gitkkal-skills

> 한국어 표현 "기깔나다"에서 이름을 따왔습니다.

[English](./README.md)

Codex, Claude 같은 특정 도구에 종속되지 않는, 브랜치 명명·커밋 생성·PR 작성에 특화된 Git 워크플로우 스킬 번들입니다.

## 포함된 스킬

- `gitkkal-init`: `.gitkkal/config.json` 생성/갱신 및 PR 템플릿(선택) 생성
- `gitkkal-branch`: 코드 변경이나 힌트를 바탕으로 의미 있는 브랜치 이름 생성
- `gitkkal-commit`: 설정한 메시지 스타일로 의미 단위 커밋 생성
- `gitkkal-pr`: 브랜치 의도와 변경 내역 기반으로 PR 생성/업데이트

## 빠른 시작

에이전트 환경에 맞는 호출 방식을 사용하세요.

```text
gitkkal-init
gitkkal-branch [description]
gitkkal-commit [hint]
gitkkal-pr [hint]
```

예시:

```text
gitkkal-init
gitkkal-branch add user authentication
gitkkal-commit emphasize validation and tests
gitkkal-pr focus on retry logic and error handling
```

## 기본 워크플로우

1. 브랜치 생성:
   - `gitkkal-branch add user authentication`
2. 변경사항 커밋:
   - `gitkkal-commit`
3. PR 생성:
   - `gitkkal-pr`
4. 추가 커밋 후 같은 PR 갱신:
   - `gitkkal-pr emphasize refactoring scope`

## 힌트 중심 동작

- `gitkkal-branch`, `gitkkal-commit`, `gitkkal-pr`는 선택적으로 자유 형식의 단일 힌트를 받습니다.
- 힌트는 참고 값이지, 강제 파라미터가 아닙니다.
- 힌트가 없으면 `git diff`/`git log`를 바탕으로 의도를 추론합니다.
- 힌트와 변경사항이 충돌하면, 확인 질문을 통해 정확히 정리합니다.

## 설정

`gitkkal-init` 실행 시 `.gitkkal/config.json`이 생성됩니다.

```json
{
  "language": "en",
  "commitPattern": "conventional",
  "branchPattern": "type/description",
  "splitCommits": true,
  "askOnAmbiguity": true,
  "createPrTemplate": false
}
```

| 옵션               | 값                                         | 설명                                    |
| ------------------ | ------------------------------------------ | --------------------------------------- |
| `language`         | `"en"`, `"ko"`                             | 출력 언어                               |
| `commitPattern`    | `"conventional"`, `"gitmoji"`, `"simple"`  | 커밋 메시지 포맷                        |
| `branchPattern`    | `"type/description"`, `"description-only"` | 브랜치 명명 형식                        |
| `splitCommits`     | `true`, `false`                            | 변경사항을 의미 단위로 분리해 커밋      |
| `askOnAmbiguity`   | `true`, `false`                            | 의도가 불명확할 때 사용자 확인          |
| `createPrTemplate` | `true`, `false`                            | `.github/PULL_REQUEST_TEMPLATE.md` 생성 |

설정 파일이 없으면 기본값이 사용됩니다.

## PR 템플릿 생성

`createPrTemplate=true`일 때 `gitkkal-init`는 프로젝트 성숙도를 판별합니다.

- `greenfield`: 기본 템플릿(`Summary`, `Changes`, `Test Plan`, `Checklist`)을 생성
- `grayfield`: 로컬 문서/워크플로우/최근 PR 템플릿을 참고해 프로젝트 관례에 맞게 템플릿을 맞춤 생성

- `greenfield`: 아직 확립된 PR 관례가 없는 신규/초기 프로젝트
- `grayfield`: 문서, 워크플로우, 과거 PR 템플릿 등을 통해 관례가 이미 형성된 기존 프로젝트

기존 템플릿 파일은 사용자 확인 없이는 덮어쓰지 않습니다.

## 설치 (Codex)

전체 스킬 설치:

```bash
bash adapters/codex/install.sh
```

특정 스킬만 설치:

```bash
bash adapters/codex/install.sh gitkkal-init gitkkal-commit
```

## 설치 (Claude)

사용자 범위 (`~/.claude/skills`):

```bash
bash adapters/claude/install.sh --scope user
```

프로젝트 범위 (`<project>/.claude/skills`):

```bash
bash adapters/claude/install.sh --scope project --project-root /path/to/project
```

## 요구사항

- Git 저장소
- PR 생성·업데이트를 위한 `gh`(GitHub CLI)

`gh`가 없으면 `gitkkal-pr`는 PR 제목/본문과 실행 명령만 생성하는 폴백 모드로 동작합니다.

## 저장소 구조

```text
skills/                 # 재사용 가능한 스킬 정의
adapters/codex/         # Codex 설치 헬퍼
adapters/claude/        # Claude 설치 헬퍼
scripts/                # 검증/패키징 스크립트
.github/workflows/      # 릴리스 자동화
```

## 검증

```bash
bash scripts/validate.sh
```

## 릴리스

로컬 태그 생성(최초 커밋 이후):

```bash
bash scripts/create-release-tag.sh v1.0.0
```

준비되면 태그 푸시:

```bash
git push origin v1.0.0
```

GitHub Actions가 각 스킬을 `tar.gz`로 패키징해 릴리스 아티팩트로 업로드합니다.
